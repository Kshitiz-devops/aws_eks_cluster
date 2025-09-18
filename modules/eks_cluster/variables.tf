########################################
# Core / Environment
########################################
variable "environment" {
  description = "Environment tag applied to all resources."
  type        = string
  default     = "prod"
}

variable "cluster_name" {
  description = "Base name for the EKS cluster. The module appends a short random suffix."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster (module var: kubernetes_version)."
  type        = string
  default     = "1.30"
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

########################################
# VPC / Networking
########################################
variable "vpc_id" {
  description = "VPC ID for the EKS cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for control plane and node groups."
  type        = list(string)
}

variable "enable_public_endpoint" {
  description = "Enable public EKS API endpoint (CIDR-scoped). Keep false for prod when possible."
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "CIDR blocks allowed to access the public API endpoint when enabled."
  type        = list(string)
  default     = []
}

########################################
# Control Plane Logging / Encryption
########################################
variable "enabled_log_types" {
  description = "EKS control plane log types to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "disk_encryption_kms_key_arn" {
  description = "KMS key ARN for node volumes (used in launch template gp3 encryption). Leave empty to use alias/aws/ebs."
  type        = string
  default     = ""
}

variable "encryption_config" {
  description = <<EOT
Cluster secrets encryption config for EKS (v21 `encryption_config`):
Example:
{
  provider_key_arn = "arn:aws:kms:region:acct:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
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
# IAM for Cluster (v21 top-level IAM inputs)
########################################
variable "iam_role_arn" {
  description = "Existing IAM role ARN for the EKS cluster. If null and create_iam_role=true, a role will be created by the module."
  type        = string
  default     = null
  nullable    = true
}

variable "create_iam_role" {
  description = "Let the module create the cluster IAM role."
  type        = bool
  default     = true
}

variable "iam_role_use_name_prefix" {
  description = "Use name prefix for the cluster IAM role when creating."
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name for the cluster IAM role (when creating). If null, a name is derived from cluster_name."
  type        = string
  default     = null
  nullable    = true
}

variable "iam_role_path" {
  description = "Path for cluster IAM role (when creating)."
  type        = string
  default     = "/"
}

variable "iam_role_permissions_boundary" {
  description = "Permissions boundary ARN for the cluster IAM role (when creating)."
  type        = string
  default     = null
  nullable    = true
}

# (Leftover guard you referenced)
variable "cluster_iam" {
  description = "Compatibility object for external condition checks (only 'create_iam_role' used)."
  type = object({
    create_iam_role = optional(bool, true)
  })
  default = {
    create_iam_role = true
  }
}

########################################
# Security Groups (v21 names)
########################################
variable "security_group_id" {
  description = "Existing cluster security group ID (if not creating a new one)."
  type        = string
  default     = ""
}

variable "additional_sg_ids" {
  description = "Additional security group IDs to associate with the control plane."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Create the cluster security group."
  type        = bool
  default     = true
}

variable "security_group_additional_rules" {
  description = "Additional rules for the cluster security group."
  type        = map(any)
  default     = {}
}

########################################
# Node Groups
########################################
variable "node_ami_type" {
  description = "AMI type for managed node groups (e.g., AL2023_x86_64, AL2_x86_64, BOTTLEROCKET_x86_64, AL2023_ARM_64)."
  type        = string
  default     = "AL2023_x86_64"
}

variable "node_disk_size" {
  description = "Root EBS volume size for nodes."
  type        = number
  default     = 50
}

variable "node_pre_userdata" {
  description = "Optional additional user-data to run before bootstrap on nodes."
  type        = string
  default     = ""
}

variable "node_groups" {
  description = <<EOT
Map of EKS managed node groups. Example:
{
  on_demand = {
    min_size       = 2
    max_size       = 6
    desired_size   = 3
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"
    subnet_ids     = ["subnet-aaa","subnet-bbb"]
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
    capacity_type  = string # ON_DEMAND or SPOT
    subnet_ids     = list(string)
    labels         = map(string)
    taints = map(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
    }))
  }))
  default = {}
}

variable "node_security_group_id" {
  description = "Existing node security group ID (if not creating a new one)."
  type        = string
  default     = ""
}

variable "create_node_security_group" {
  description = "Create the node security group."
  type        = bool
  default     = true
}

variable "node_sg_additional_rules" {
  description = "Additional rules for the node security group."
  type = map(object({
    description                = optional(string)
    protocol                   = string
    from_port                  = number
    to_port                    = number
    type                       = string # "ingress" | "egress"
    cidr_blocks                = optional(list(string))
    ipv6_cidr_blocks           = optional(list(string))
    prefix_list_ids            = optional(list(string))
    self                       = optional(bool)
    source_security_group_id   = optional(string)
    source_node_security_group = optional(bool)
  }))

  default = {
    ingress_self_all = {
      description = "Node to node all traffic"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node egress to anywhere"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}


########################################
# Addons (v21)
########################################
variable "addons_overrides" {
  description = "Overrides/extra EKS addons merged on top of the defaults (coredns, kube-proxy, vpc-cni, aws-ebs-csi-driver)."
  type        = map(any)
  default     = {}
}

########################################
# Access Management (v21 replaces aws-auth)
########################################
variable "enable_cluster_creator_admin_permissions" {
  description = "If true, bootstrap the current caller as cluster-admin via Access Entry."
  type        = bool
  default     = false
}

variable "access_entries" {
  description = <<EOT
Access entries map for EKS (v21). Example:
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
    type              = optional(string) # STANDARD, EC2_LINUX, etc.
    user_name         = optional(string)
    kubernetes_groups = optional(list(string))
    policy_associations = map(object({
      policy_arn = string
      access_scope = object({
        type       = string # "cluster" or "namespace"
        namespaces = optional(list(string))
      })
    }))
    tags = optional(map(string))
  }))
  default = {}
}

########################################
# (Optional) Legacy aws-auth submodule
########################################
variable "aws_auth_roles" {
  description = "If you still use the aws-auth submodule, supply role mappings here."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}
