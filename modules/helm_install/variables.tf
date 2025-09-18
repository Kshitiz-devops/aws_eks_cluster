variable "cluster_name" {
  type        = string
  description = "EKS cluster name (for reference only)"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint (from eks_cluster module)"
}

variable "cluster_ca_data" {
  type        = string
  description = "EKS cluster CA data (from eks_cluster module)"
}

variable "cluster_auth_token" {
  type        = string
  description = "Authentication token for cluster access (usually from aws_eks_cluster_auth)"
}

variable "charts" {
  description = <<EOT
A map of Helm chart configs to install.
Example:
{
  cilium = {
    chart     = "cilium"
    repo      = "https://helm.cilium.io/"
    version   = "1.16.1"
    namespace = "kube-system"
    values    = [file("values/cilium.yaml")]
  }
}
EOT
  type = map(object({
    chart     = string
    repo      = string
    version   = optional(string)
    namespace = optional(string, "default")
    values    = optional(list(string), [])
  }))
}
