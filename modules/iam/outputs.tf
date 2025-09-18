output "node_instance_role_arn" {
  description = "IAM Role ARN used by the EKS worker node group instances."
  value       = aws_iam_role.node.arn
}

output "irsa_ca_role_arn" {
  description = "IAM Role ARN for the Cluster Autoscaler service account (IRSA)."
  value       = aws_iam_role.irsa_cluster_autoscaler.arn
}

output "irsa_alb_role_arn" {
  description = "IAM Role ARN for the AWS Load Balancer Controller service account (IRSA)."
  value       = aws_iam_role.irsa_alb.arn
}

output "irsa_ebs_csi_role_arn" {
  description = "IAM Role ARN for the Amazon EBS CSI driver service account (IRSA)."
  value       = aws_iam_role.irsa_ebs_csi.arn
}
