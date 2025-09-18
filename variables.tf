########################################
# Core / Environment
########################################
variable "cluster_name" {
  description = "Base name for the EKS cluster."
  type        = string
}

variable "region" {
  description = "AWS region to deploy to"
  type        = string

}

variable "cluster_version" {
  description = "Kubernetes version to use (passed to the eks_cluster module)."
  type        = string
  default     = "1.30"
}

variable "environment" {
  description = "Environment tag applied to resources."
  type        = string
  default     = "prod"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}

########################################
# VPC / Networking
########################################
variable "vpc_id" {
  description = "VPC ID in which to deploy the cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (used for control plane and private node groups)."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (used when a node group sets subnet_type = \"public\")."
  type        = list(string)
  default     = []
}

variable "enable_public_endpoint" {
  description = "Enable public access to the EKS API endpoint (recommend false in prod)."
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint when enabled."
  type        = list(string)
  default     = []

  # Validate only this variable (no cross-variable references allowed)
  validation {
    condition     = alltrue([for c in var.allowed_public_cidrs : can(cidrnetmask(c))])
    error_message = "Each entry in allowed_public_cidrs must be a valid IPv4/IPv6 CIDR (e.g., 203.0.113.0/24)."
  }
}


########################################
# Encryption (v21: encryption_config)
########################################
variable "encryption_config" {
  description = <<EOT
EKS secrets encryption configuration (v21 style).
Example:
{
  provider_key_arn = "arn:aws:kms:REGION:ACCOUNT:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  resources        = ["secrets"]
}
EOT
  type = object({
    provider_key_arn = string
    resources        = list(string)
  })
  default  = null
  nullable = true
}

########################################
# Node Groups (with subnet_type switch)
########################################
variable "node_groups" {
  description = <<EOT
Map of EKS managed node groups. Each group must include `subnet_type` with value "private" or "public".
Example:
{
  on_demand = {
    min_size       = 2
    max_size       = 6
    desired_size   = 3
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"               # or "SPOT"
    subnet_type    = "private"                  # "private" | "public"
    labels         = { workload = "general" }
    taints         = {}
  }
}
EOT
  type = map(object({
    min_size       = number
    max_size       = number
    desired_size   = number
    instance_types = list(string)
    capacity_type  = string
    subnet_type    = string
    labels         = map(string)
    taints = map(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE | NO_EXECUTE | PREFER_NO_SCHEDULE
    }))
  }))
  default = {}

  validation {
    condition     = alltrue([for _, g in var.node_groups : contains(["private", "public"], lower(g.subnet_type))])
    error_message = "Each node group must set subnet_type to either \"private\" or \"public\"."
  }
}

########################################
# Access Management (v21 preferred)
########################################
variable "enable_cluster_creator_admin_permissions" {
  description = "Bootstrap the current caller as cluster-admin via Access Entry."
  type        = bool
  default     = false
}

variable "access_entries" {
  description = <<EOT
EKS access entries (v21). Example:
{
  platform_admin = {
    principal_arn = "arn:aws:iam::123456789012:role/PlatformAdmin"
    type          = "STANDARD"
    kubernetes_groups = ["system:masters"]
    policy_associations = {
      admin = {
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
        access_scope = { type = "cluster" }
      }
    }
    tags = { team = "platform" }
  }
}
EOT
  type = map(object({
    principal_arn     = string
    type              = optional(string)
    user_name         = optional(string)
    kubernetes_groups = optional(list(string))
    policy_associations = map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string))
      })
    }))
    tags = optional(map(string))
  }))
  default = {}
}

########################################
# (Optional) Legacy aws-auth compatibility
########################################
variable "admin_role_arn" {
  description = "Admin role ARN to map via legacy aws-auth (if still used)."
  type        = string
  default     = ""
}

variable "extra_aws_auth_roles" {
  description = "Extra role mappings for legacy aws-auth."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

########################################
# IAM path / permissions boundary (passthroughs)
########################################
variable "iam_role_path" {
  description = "Path for the cluster IAM role (passed to eks_cluster module)."
  type        = string
  default     = "/"
}

variable "iam_role_permissions_boundary" {
  description = "Permissions boundary ARN for the cluster IAM role (passed to eks_cluster module)."
  type        = string
  default     = null
  nullable    = true
}

# For the separate IAM module
variable "iam_path" {
  description = "Path for IAM resources created by the IAM submodule."
  type        = string
  default     = "/"
}

variable "permissions_boundary_arn" {
  description = "Permissions boundary ARN for IAM roles created by the IAM submodule."
  type        = string
  default     = null
  nullable    = true
}
