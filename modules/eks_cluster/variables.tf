variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster."
  type        = list(string)
}

# variable "public_subnet_ids" {
#   description = "List of public subnet IDs for the EKS cluster."
#   type        = list(string)
# }

variable "enable_public_endpoint" {
  description = "Whether to enable public access to the EKS cluster endpoint."
  type        = bool
  default     = false
}

variable "allowed_public_cidrs" {
  description = "List of CIDR blocks allowed to access the public endpoint."
  type        = list(string)
  default     = []
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR block for the Kubernetes service IPs."
  type        = string
  default     = null
}

variable "cluster_security_group_id" {
  description = "Existing security group ID for the EKS cluster (optional)."
  type        = string
  default     = ""
}

variable "cluster_additional_sg_ids" {
  description = "List of additional security group IDs to attach to the cluster."
  type        = list(string)
  default     = []
}

variable "create_cluster_security_group" {
  description = "Whether to create a new security group for the cluster."
  type        = bool
  default     = true
}

variable "cluster_sg_additional_rules" {
  description = "Additional rules for the cluster security group."
  type        = map(any)
  default     = {}
}

variable "node_security_group_id" {
  description = "Existing security group ID for worker nodes (optional)."
  type        = string
  default     = ""
}

variable "create_node_security_group" {
  description = "Whether to create a new security group for worker nodes."
  type        = bool
  default     = true
}

variable "node_sg_additional_rules" {
  description = "Additional rules for the node security group."
  type = map(object({
    description      = string
    protocol         = string
    from_port        = number
    to_port          = number
    type             = string
    cidr_blocks      = optional(list(string))
    ipv6_cidr_blocks = optional(list(string))
    self             = optional(bool)
  }))

  default = {
    ingress_self_all = {
      description = "Allow node-to-node communication on all ports/protocols."
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }

    egress_all = {
      description      = "Allow all outbound traffic from nodes."
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}


variable "cluster_enabled_log_types" {
  description = "List of EKS control plane log types to enable (API, Audit, Authenticator, ControllerManager, Scheduler)."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_encryption_config" {
  description = "EKS encryption configuration for secrets using KMS."
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

variable "disk_encryption_kms_key_arn" {
  description = "Custom KMS key ARN for EBS volume encryption (optional)."
  type        = string
  default     = ""
}


variable "node_ami_type" {
  description = "AMI type for worker nodes (e.g., AL2_x86_64, BOTTLEROCKET_x86_64)."
  type        = string
  default     = "AL2_x86_64"
}

variable "node_disk_size" {
  description = "Disk size (in GiB) for worker nodes."
  type        = number
  default     = 50
}

variable "node_pre_userdata" {
  description = "Custom user data script to run before the default bootstrap script on nodes."
  type        = string
  default     = ""
}

variable "node_groups" {
  description = "Map of EKS managed node groups and their configuration."
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
      effect = string
    }))
  }))
  default = {}
}

variable "aws_auth_roles" {
  description = "List of IAM role mappings for aws-auth ConfigMap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_iam" {
  description = "Configuration for EKS cluster IAM role (create or provide existing)."
  type = object({
    create_iam_role               = optional(bool, true)
    iam_role_arn                  = optional(string)
    iam_role_name                 = optional(string)
    iam_role_path                 = optional(string, "/")
    iam_role_use_name_prefix      = optional(bool, true)
    iam_role_permissions_boundary = optional(string)
  })
  default = {
    create_iam_role = true
  }
}

variable "iam_path" {
  description = "IAM path for roles and policies."
  type        = string
  default     = "/"
}

variable "permissions_boundary_arn" {
  description = "IAM permissions boundary ARN for roles (optional)."
  type        = string
  default     = null
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "cilium_version" {
  description = "Cilium Helm chart version to install"
  type        = string
  default     = "1.16.1"
}
