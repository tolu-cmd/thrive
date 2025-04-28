provider "aws" {
  region = var.aws_region
}

# Create a VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"  # Pinning to a specific version compatible with AWS provider v4.x

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Environment                                 = var.environment
    Project                                     = var.project_name
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

# Create EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"  # Pinning to a specific version compatible with AWS provider v4.x

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    disk_size      = 20
    instance_types = ["t3.small"]  # Changed to t3.small for better capacity
  }

  eks_managed_node_groups = {
    main = {
      min_size     = var.min_nodes
      max_size     = var.max_nodes
      desired_size = var.desired_nodes

      instance_types = ["t3.small"]  # Changed to t3.small for better capacity
      capacity_type  = "ON_DEMAND"
    }
  }

  # Allow worker nodes to assume role to access other AWS services
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create IAM role for ALB controller
module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.1"  # Pinning to a specific version compatible with AWS provider v4.x

  role_name                              = "${var.project_name}-eks-lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
