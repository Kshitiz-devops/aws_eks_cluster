locals {
  node_groups = {
    for name, group in var.node_groups : name => merge(group, {
      subnet_ids = group.subnet_type == "public" ? var.public_subnet_ids : var.private_subnet_ids
    })
  }
}

module "eks_cluster" {
  source = "./modules/eks_cluster"

  # Core
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = var.environment

  # Networking
  vpc_id                 = var.vpc_id
  private_subnet_ids     = var.private_subnet_ids
  enable_public_endpoint = var.enable_public_endpoint
  allowed_public_cidrs   = var.allowed_public_cidrs
  # If you expose service_ipv4_cidr in your wrapper, you can pass it here:
  # service_ipv4_cidr = var.service_ipv4_cidr

  # Security groups (v21 naming)
  create_security_group      = true
  create_node_security_group = true
  # Optionally pass additional SGs/rules if you’ve surfaced them:
  # additional_sg_ids               = var.additional_sg_ids
  # security_group_additional_rules = var.security_group_additional_rules
  # node_security_group_id          = var.node_security_group_id
  # node_sg_additional_rules        = var.node_sg_additional_rules

  # Encryption (v21: encryption_config)
  encryption_config = var.encryption_config

  # Node groups
  node_groups = local.node_groups

  # v21 access entries (preferred over aws-auth)
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  access_entries                           = var.access_entries

  # Legacy aws-auth (keep only if you still need it)
  aws_auth_roles = concat(
    [
      {
        rolearn  = var.admin_role_arn
        username = "admin:{{SessionName}}"
        groups   = ["system:masters"]
      }
    ],
    var.extra_aws_auth_roles
  )

  # IAM path / permissions boundary (v21 names)
  iam_role_path                 = var.iam_role_path
  iam_role_permissions_boundary = var.iam_role_permissions_boundary

  # Tags
  additional_tags = var.additional_tags
}


# Build OIDC trust document for IRSA roles
data "aws_iam_policy_document" "oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks_cluster.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks_cluster.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
    # Fine-grain service accounts can also be constrained here by "sub" later if desired
  }
}

# Canonical policies for ALB + EBS CSI (kept as files or templatefile()s)
locals {
  alb_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      }
    ]
  })

  ebs_csi_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:DescribeVolume*",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      }
    ]
  })
}


module "iam" {
  source = "./modules/iam"

  cluster_name               = var.cluster_name
  iam_path                   = var.iam_path
  permissions_boundary_arn   = var.permissions_boundary_arn
  oidc_assume_role_policy    = data.aws_iam_policy_document.oidc_trust.json
  alb_controller_policy_json = local.alb_policy_json
  ebs_csi_policy_json        = local.ebs_csi_policy_json

  additional_tags = var.additional_tags
}

# Optionally tag VPC/subnets for K8s ELBs
module "vpc_tags" {
  source = "./modules/vpc_tags"

  cluster_name = var.cluster_name
  vpc_id       = var.vpc_id
  #   public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
}



data "aws_eks_cluster" "this" {
  name = module.eks_cluster.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.cluster_name
}

module "helm_install" {
  source = "./modules/helm_install"

  cluster_name       = module.eks_cluster.cluster_name
  cluster_endpoint   = data.aws_eks_cluster.this.endpoint
  cluster_ca_data    = data.aws_eks_cluster.this.certificate_authority[0].data
  cluster_auth_token = data.aws_eks_cluster_auth.this.token

  charts = {
    cilium = {
      chart     = "cilium"
      repo      = "https://helm.cilium.io/"
      version   = "1.16.1"
      namespace = "kube-system"
      values = [yamlencode({
        kubeProxyReplacement = "strict"
        securityContext = {
          capabilities = {
            ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
            cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN"]
          }
          privileged = true
        }
        hostServices = { enabled = false }
        externalIPs  = { enabled = true }
        nodePort     = { enabled = true }
        hostPort     = { enabled = true }
        l7Proxy      = { enabled = true }
        ipam         = { mode = "kubernetes" }
      })]
    }
  }
}

