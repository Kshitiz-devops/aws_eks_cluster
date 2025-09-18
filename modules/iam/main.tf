terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

data "aws_partition" "current" {}
locals {
  partition = data.aws_partition.current.partition
  tags      = merge({ "ManagedBy" = "terraform" }, var.additional_tags)
}

# Node group role (separate from cluster role) – often useful to manage aws-auth cleanly
data "aws_iam_policy_document" "ng_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name                 = "${var.cluster_name}-ng-role"
  assume_role_policy   = data.aws_iam_policy_document.ng_assume_role.json
  path                 = var.iam_path
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ---- IRSA roles ----

# Cluster Autoscaler
data "aws_iam_policy_document" "cluster_autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "${var.cluster_name}-cluster-autoscaler"
  description = "Permissions for Cluster Autoscaler"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
  tags        = local.tags
}

resource "aws_iam_role" "irsa_cluster_autoscaler" {
  name                 = "${var.cluster_name}-irsa-ca"
  assume_role_policy   = var.oidc_assume_role_policy
  permissions_boundary = var.permissions_boundary_arn
  path                 = var.iam_path
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "irsa_ca_attach" {
  role       = aws_iam_role.irsa_cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

# AWS Load Balancer Controller
resource "aws_iam_policy" "alb_controller" {
  name        = "${var.cluster_name}-alb-controller"
  description = "AWS Load Balancer Controller recommended policy"
  policy      = var.alb_controller_policy_json
  tags        = local.tags
}

resource "aws_iam_role" "irsa_alb" {
  name                 = "${var.cluster_name}-irsa-alb"
  assume_role_policy   = var.oidc_assume_role_policy
  permissions_boundary = var.permissions_boundary_arn
  path                 = var.iam_path
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.irsa_alb.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# EBS CSI Controller (recommended when using AWS-managed addon)
resource "aws_iam_policy" "ebs_csi_controller" {
  name        = "${var.cluster_name}-ebs-csi"
  description = "EBS CSI controller policy"
  policy      = var.ebs_csi_policy_json
  tags        = local.tags
}

resource "aws_iam_role" "irsa_ebs_csi" {
  name                 = "${var.cluster_name}-irsa-ebs-csi"
  assume_role_policy   = var.oidc_assume_role_policy
  permissions_boundary = var.permissions_boundary_arn
  path                 = var.iam_path
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.irsa_ebs_csi.name
  policy_arn = aws_iam_policy.ebs_csi_controller.arn
}
