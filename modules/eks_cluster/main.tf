terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_kms_key" "ebs_default" {
  key_id = "alias/aws/ebs"
}

locals {
  aws_partition   = data.aws_partition.current.partition
  account_id      = data.aws_caller_identity.current.account_id
  ebs_kms_key     = var.disk_encryption_kms_key_arn != "" ? var.disk_encryption_kms_key_arn : data.aws_kms_key.ebs_default.arn
  cluster_subnets = concat(var.private_subnet_ids, var.public_subnet_ids)

  tags = merge({
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "ClusterName" = var.cluster_name
  }, var.additional_tags)
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false

}
module "eks" {
  # Official AWS EKS module (as requested)
  source  = "terraform-aws-modules/eks/aws"
  version = "20.29.0"

  cluster_name    = "${var.cluster_name}-${random_string.suffix.result}"
  cluster_version = var.cluster_version

  # Endpoint access (prod-friendly: private on, public cidr-scoped toggle)
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.enable_public_endpoint
  cluster_endpoint_public_access_cidrs = var.allowed_public_cidrs

  # IRSA
  enable_irsa              = true
  openid_connect_audiences = ["sts.amazonaws.com"]

  # Control plane logs
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # Envelope encryption (KMS for secrets)
  cluster_encryption_config      = var.cluster_encryption_config
  cluster_encryption_policy_path = var.iam_path

  # Cluster IAM role (can be created here or passed in)
  iam_role_arn                  = try(var.cluster_iam.iam_role_arn, null)
  create_iam_role               = try(var.cluster_iam.create_iam_role, true)
  iam_role_use_name_prefix      = try(var.cluster_iam.iam_role_use_name_prefix, true)
  iam_role_name                 = try(var.cluster_iam.iam_role_name, substr("${var.cluster_name}-cluster", 0, 37), null)
  iam_role_path                 = try(var.cluster_iam.iam_role_path, var.iam_path, "/")
  iam_role_permissions_boundary = try(var.cluster_iam.iam_role_permissions_boundary, var.permissions_boundary_arn, null)

  vpc_id                                     = var.vpc_id
  control_plane_subnet_ids                   = local.cluster_subnets
  cluster_service_ipv4_cidr                  = var.cluster_service_ipv4_cidr
  cluster_security_group_id                  = var.cluster_security_group_id
  cluster_additional_security_group_ids      = var.cluster_additional_sg_ids
  create_cluster_security_group              = var.create_cluster_security_group
  cluster_security_group_additional_rules    = var.cluster_sg_additional_rules
  create_cluster_primary_security_group_tags = false

  # EKS managed node groups (prod defaults → gp3 + encrypted, IRSA-ready)
  eks_managed_node_group_defaults = {
    ami_type               = var.node_ami_type
    disk_size              = var.node_disk_size
    enable_monitoring      = true
    ebs_optimized          = true
    create_launch_template = true
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = var.node_disk_size
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = local.ebs_kms_key
          delete_on_termination = true
        }
      }
    }
    update_config = {
      max_unavailable = 1
    }
    pre_bootstrap_user_data = var.node_pre_userdata
    tags = merge({
      "k8s.io/cluster-autoscaler/enabled"             = "true",
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "ClusterName"                                   = var.cluster_name
    }, local.tags)
  }

  eks_managed_node_groups = var.node_groups

  node_security_group_id               = var.node_security_group_id
  create_node_security_group           = var.create_node_security_group
  node_security_group_additional_rules = var.node_sg_additional_rules

  # Core addons (use most recent)
  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    # Enable EBS CSI as an AWS-managed addon (strongly recommended in prod)
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  bootstrap_self_managed_addons = false
  tags                          = local.tags
}

# Manage aws-auth map (role bindings)
module "eks_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "20.29.0"

  manage_aws_auth_configmap = true
  aws_auth_roles            = var.aws_auth_roles

  depends_on = [module.eks]
}

# Optional: tag the cluster’s primary SG for ops hygiene
resource "aws_ec2_tag" "cluster_primary_sg_vendor" {
  count       = module.eks.cluster_primary_security_group_id != "" ? 1 : 0
  resource_id = module.eks.cluster_primary_security_group_id
  key         = "Vendor"
  value       = "terraform"
}

### Cluster IAM Role (created here if not provided)
data "aws_iam_policy_document" "cluster_assume_role" {
  count = try(var.cluster_iam.create_iam_role, true) ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}


