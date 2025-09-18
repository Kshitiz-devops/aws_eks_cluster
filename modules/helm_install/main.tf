terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_data)
  token                  = var.cluster_auth_token
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}

# Loop over all requested charts
resource "helm_release" "this" {
  for_each = var.charts

  name       = each.key
  repository = lookup(each.value, "repo", null)
  chart      = lookup(each.value, "chart", null)
  version    = lookup(each.value, "version", null)
  namespace  = lookup(each.value, "namespace", "default")

  create_namespace = true

  values = lookup(each.value, "values", [])

  # In case we want dependency control
  timeout         = 600
  atomic          = true
  cleanup_on_fail = true
}
