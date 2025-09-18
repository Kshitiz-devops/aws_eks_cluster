output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data required to communicate with the cluster."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  description = "Security Group ID attached to the EKS cluster."
  value       = module.eks.cluster_security_group_id
}

output "cluster_primary_sg_id" {
  description = "Primary Security Group ID created by EKS for the cluster."
  value       = module.eks.cluster_primary_security_group_id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider associated with the EKS cluster (used for IRSA)."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider" {
  description = "EKS OIDC provider URL without the https:// prefix."
  value       = module.eks.oidc_provider
}

output "node_security_group_id" {
  description = "Security Group ID attached to worker nodes in the EKS cluster."
  value       = module.eks.node_security_group_id
}
