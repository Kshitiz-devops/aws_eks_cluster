variable "cluster_name" {
  description = "Name of the EKS cluster. Used for tagging and IAM resource naming."
  type        = string
}

variable "iam_path" {
  description = "IAM path for roles and policies (e.g., '/service-role/')."
  type        = string
  default     = "/"
}

variable "permissions_boundary_arn" {
  description = "ARN of the IAM permissions boundary policy to attach to roles (optional)."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional tags to attach to IAM roles and policies."
  type        = map(string)
  default     = {}
}

variable "oidc_assume_role_policy" {
  description = <<EOT
Rendered OIDC trust policy JSON document.
Typically built using outputs from the EKS module (e.g., module.eks.oidc_provider_arn).
Required for IRSA-enabled service accounts.
EOT
  type        = string
}

variable "alb_controller_policy_json" {
  description = <<EOT
IAM policy JSON for the AWS Load Balancer Controller.
Store canonical JSON in the repo or use templatefile() to render.
EOT
  type        = string
}

variable "ebs_csi_policy_json" {
  description = <<EOT
IAM policy JSON for the Amazon EBS CSI driver.
Store canonical JSON in the repo or use templatefile() to render.
EOT
  type        = string
}
