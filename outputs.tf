######################################
# EKS Cluster Outputs
######################################

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "API server endpoint for the EKS cluster."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data for cluster authentication."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "Security Group ID attached to the EKS control plane."
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_sg_id" {
  description = "Primary security group created by EKS for managed workloads."
  value       = module.eks.cluster_primary_security_group_id
}

######################################
# OIDC Provider
######################################

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for the EKS cluster."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "Issuer URL for the IAM OIDC provider (used for IRSA)."
  value       = module.eks.oidc_provider
}

######################################
# Node Group Outputs
######################################

output "node_security_group_id" {
  description = "Security Group ID associated with the worker nodes."
  value       = module.eks.node_security_group_id
}

######################################
# IAM Role Outputs (from iam/ module)
######################################

output "cluster_iam_role_arn" {
  description = "IAM role ARN used by the EKS control plane."
  value       = module.iam.cluster_iam_role_arn
}

output "node_instance_role_arn" {
  description = "IAM role ARN used by EKS worker node instances."
  value       = module.iam.node_instance_role_arn
}

output "irsa_ca_role_arn" {
  description = "IAM role ARN for Cluster Autoscaler (IRSA)."
  value       = module.iam.irsa_ca_role_arn
}

output "irsa_alb_role_arn" {
  description = "IAM role ARN for AWS Load Balancer Controller (IRSA)."
  value       = module.iam.irsa_alb_role_arn
}

output "irsa_ebs_csi_role_arn" {
  description = "IAM role ARN for EBS CSI Driver (IRSA)."
  value       = module.iam.irsa_ebs_csi_role_arn
}
