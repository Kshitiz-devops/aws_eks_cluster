terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_kms_key" "ebs_default" {
  key_id = "alias/aws/ebs"
}

locals {
  aws_partition = data.aws_partition.current.partition
  account_id    = data.aws_caller_identity.current.account_id
  ebs_kms_key   = var.disk_encryption_kms_key_arn != "" ? var.disk_encryption_kms_key_arn : data.aws_kms_key.ebs_default.arn

  # keep control plane in private subnets
  cluster_subnets = var.private_subnet_ids

  tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
    ClusterName = var.cluster_name
  }, var.additional_tags)
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "eks" {
  # v21.x interface
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.1"

  name               = "${var.cluster_name}-${random_string.suffix.result}"
  kubernetes_version = var.cluster_version

  endpoint_private_access      = true
  endpoint_public_access       = var.enable_public_endpoint
  endpoint_public_access_cidrs = var.allowed_public_cidrs

  enable_irsa              = true
  openid_connect_audiences = ["sts.amazonaws.com"]

  enabled_log_types = var.enabled_log_types

  encryption_config = var.encryption_config

  # Cluster IAM role — v21 uses top-level IAM vars (not object `cluster_iam.*`)
  iam_role_arn                  = var.iam_role_arn
  create_iam_role               = var.create_iam_role
  iam_role_use_name_prefix      = var.iam_role_use_name_prefix
  iam_role_name                 = var.iam_role_name != null ? var.iam_role_name : substr("${var.cluster_name}-cluster", 0, 37)
  iam_role_path                 = var.iam_role_path
  iam_role_permissions_boundary = var.iam_role_permissions_boundary


  vpc_id                   = var.vpc_id
  subnet_ids               = local.cluster_subnets
  control_plane_subnet_ids = local.cluster_subnets

  # ❗ v21 renames SG inputs
  security_group_id                  = var.security_group_id
  additional_security_group_ids      = var.additional_sg_ids
  create_security_group              = var.create_security_group
  security_group_additional_rules    = var.security_group_additional_rules
  create_primary_security_group_tags = false

  # EKS managed node groups (unchanged structure)
  #   eks_managed_node_group_defaults = {
  #     ami_type               = var.node_ami_type
  #     disk_size              = var.node_disk_size
  #     enable_monitoring      = true
  #     ebs_optimized          = true
  #     create_launch_template = true
  #     block_device_mappings = {
  #       xvda = {
  #         device_name = "/dev/xvda"
  #         ebs = {
  #           volume_size           = var.node_disk_size
  #           volume_type           = "gp3"
  #           encrypted             = true
  #           kms_key_id            = local.ebs_kms_key
  #           delete_on_termination = true
  #         }
  #       }
  #     }
  #     update_config           = { max_unavailable = 1 }
  #     pre_bootstrap_user_data = var.node_pre_userdata
  #     tags = merge({
  #       "k8s.io/cluster-autoscaler/enabled"             = "true",
  #       "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
  #       "ClusterName"                                   = var.cluster_name
  #     }, local.tags)
  #   }

  eks_managed_node_groups = var.node_groups

  node_security_group_id               = var.node_security_group_id
  create_node_security_group           = var.create_node_security_group
  node_security_group_additional_rules = var.node_sg_additional_rules

  # ❗ v21 uses `addons` (not `cluster_addons`)
  addons = merge({
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }, var.addons_overrides)

  # ❗ v21 replaces `aws-auth` submodule with access entries
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                           = var.access_entries

  tags = local.tags
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


