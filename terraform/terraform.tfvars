aws_region        = "us-east-1"
project_name      = "hello-world"
environment       = "dev"
vpc_cidr          = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
private_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets    = ["10.0.101.0/24", "10.0.102.0/24"]
cluster_name      = "hello-world-eks"
kubernetes_version = "1.27"  # Updated to a supported version for AWS EKS
# Node configuration for high availability
min_nodes         = 2
max_nodes         = 3
desired_nodes     = 2
