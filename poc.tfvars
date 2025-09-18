region             = "us-east-1"
cluster_name       = "prod-eks"
cluster_version    = "1.30"
vpc_id             = "vpc-xxxxxxxx"
private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
public_subnet_ids  = ["subnet-111", "subnet-222", "subnet-333"]

enable_public_endpoint = false
allowed_public_cidrs   = ["203.0.113.0/24"]

cluster_service_ipv4_cidr = null
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

  spot-general = {
    min_size       = 0
    max_size       = 10
    desired_size   = 2
    instance_types = ["m6i.large", "m5.large"]
    capacity_type  = "SPOT"
    subnet_type    = "private" # default: private, safe
    labels         = { workload = "general-spot" }
    taints         = {}
  }
}

# KMS key to encrypt K8s secrets
cluster_encryption_config = [
  {
    provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    resources        = ["secrets"]
  }
]

admin_role_arn = "arn:aws:iam::123456789012:role/OrgAdmin"

iam_path                 = "/"
permissions_boundary_arn = null

additional_tags = {
  "CostCenter" = "platform"
  "Owner"      = "platform-team"
}

extra_aws_auth_roles = []
