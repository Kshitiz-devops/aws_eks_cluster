variable "region" {
  description = "AWS region where the EKS cluster and related resources will be deployed."
  type        = string
}

variable "cluster_name" {
  description = "Base name of the EKS cluster. A random suffix may be appended for uniqueness."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane (e.g., 1.29, 1.30)."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster and worker nodes will be provisioned."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs used for EKS worker nodes and control plane."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs used for load balancers or public-facing resources."
  type        = list(string)
}

variable "enable_public_endpoint" {
  description = "If true, allows the EKS control plane to be accessible via a public endpoint."
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "List of CIDR blocks permitted to access the public API endpoint. Empty list means unrestricted if public access is enabled."
  type        = list(string)
  default     = []
}

variable "cluster_service_ipv4_cidr" {
  description = "Optional custom CIDR block for Kubernetes service IP addresses (e.g., 172.20.0.0/16). Leave null for AWS default."
  type        = string
  default     = null
}

variable "node_groups" {
  description = <<EOT
Map of EKS managed node groups. Each group defines scaling, instance types,
capacity type, and subnet placement.

- `subnet_type`: must be either "private" or "public".

Example:
node_groups = {
  on-demand-general = {
    min_size       = 2
    max_size       = 6
    desired_size   = 3
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"
    subnet_type    = "private"
    labels         = { workload = "general" }
    taints         = {}
  }
}
EOT
  type        = map(any)
  default     = {}
}


variable "cluster_encryption_config" {
  description = <<EOT
Configuration for envelope encryption of Kubernetes secrets using AWS KMS.
Each object must include:
  - provider_key_arn : ARN of the KMS key
  - resources        : List of resources to encrypt (e.g., [\"secrets\"])
EOT
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

variable "admin_role_arn" {
  description = "ARN of the IAM role that will be granted administrator access to the EKS cluster."
  type        = string
}

variable "iam_path" {
  description = "Path under which IAM roles and policies will be created. Useful for compliance or organizational separation."
  type        = string
  default     = "/"
}

variable "permissions_boundary_arn" {
  description = "Optional ARN of the IAM permissions boundary to apply to IAM roles."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Extra tags to apply to all resources created by this module (merged with defaults)."
  type        = map(string)
  default     = {}
}

variable "extra_aws_auth_roles" {
  description = <<EOT
Additional IAM role mappings for the aws-auth ConfigMap.
Each mapping requires:
  - rolearn  : IAM role ARN
  - username : Kubernetes username to assign
  - groups   : List of Kubernetes RBAC groups to map the role into
EOT
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
