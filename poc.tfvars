# --- Region / naming ---
region          = "us-east-1"
cluster_name    = "prod-eks"
cluster_version = "1.30"

# --- VPC / subnets ---
vpc_id             = "vpc-xxxxxxxx"
private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
public_subnet_ids  = ["subnet-111", "subnet-222", "subnet-333"]

# --- API endpoint exposure ---
enable_public_endpoint = false
allowed_public_cidrs   = [] # leave empty since public endpoint is disabled

# --- EKS secrets encryption (v21: encryption_config is an OBJECT) ---
encryption_config = {
  provider_key_arn = "arn:aws:kms:us-east-1:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  resources        = ["secrets"]
}

# --- Node groups (use subnet_type to route to public/private sets) ---
node_groups = {
  sysgroup = {
    min_size       = 2
    max_size       = 2
    desired_size   = 2
    instance_types = ["m4.xlarge"]
    capacity_type  = "ON_DEMAND"
    subnet_type    = "private"
    labels         = { workload = "sysgroup" }
    taints         = {}
  }

  nodegroup1 = {
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    instance_types = ["m4.xlarge"]
    capacity_type  = "SPOT"
    subnet_type    = "private"
    labels         = { workload = "nodegroup1" }
    taints         = {}
  }
}

# --- Access management ---
# Prefer v21 access entries; leave empty if you’re still using aws-auth below.
enable_cluster_creator_admin_permissions = false
access_entries                           = {}

# Legacy aws-auth (kept for compatibility)
admin_role_arn       = "arn:aws:iam::123456789012:role/OrgAdmin"
extra_aws_auth_roles = []

# --- IAM paths / permissions boundary ---
# For the EKS module wrapper (cluster role path/boundary)
iam_role_path                 = "/"
iam_role_permissions_boundary = null

# For your separate IAM submodule (kept as-is)
iam_path                 = "/"
permissions_boundary_arn = null

# --- Tags ---
additional_tags = {
  CostCenter = "platform"
  Owner      = "platform-team"
}
