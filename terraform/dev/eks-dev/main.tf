terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "eks-cost-project-tfstates-dev"
    key            = "eks-cost-project-tfstates-dev/eks-cost-project-eks-dev.tfstate"
    profile        = "EleSangwon-dev"
    dynamodb_table = "terraform-lock"
  }
}


provider "aws" {
  region  = "ap-northeast-2"
  profile = "EleSangwon-dev"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "eks-cost-project-tfstates-dev"
    region         = "ap-northeast-2"
    key            = "eks-cost-project-tfstates-dev/eks-cost-project-vpc-dev.tfstate"
    profile        = "EleSangwon-dev"
    dynamodb_table = "terraform-lock"
  }
}

locals {
  name = "eks-cost-project-dev"
  tags = {
    Name        = local.name
    Environment = "dev"
    Project     = "eks-cost-project"
    Team        = "devops"
  }
  vpc                   = data.terraform_remote_state.vpc.outputs.vpc
  private_subnets_by_az = local.vpc.private_subnets
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.name
  cluster_version = "1.23"

  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  tags                           = local.tags

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  vpc_id     = local.vpc.vpc_id
  subnet_ids = tolist(local.private_subnets_by_az)
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium", "t3.small"]
  }

  eks_managed_node_groups = {
    project-dev-ondemand = {
      min_size       = 0
      max_size       = 1
      desired_size   = 0
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      labels = {
        Environment = "ON_DEMAND_SPOT"
        GithubRepo  = "eks-cost-project"
        GithubOrg   = "devops-sangwon"
      }
    }
    project-dev-spot = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "ONLY_SPOT"
        GithubRepo  = "eks-cost-project"
        GithubOrg   = "devops-sangwon"
      }
    }
  }
  # aws-auth configmap
  manage_aws_auth_configmap = false

  aws_auth_users = [
    {
      groups   = ["system:masters"]
      userarn  = "arn:aws:iam::002174788893:user/EleSangwon-dev"
      username = "eks-cost-project-dev-devops"
    }
  ]

  aws_auth_roles = [
    {
      groups   = ["system:masters"]
      rolearn  = "arn:aws:iam::002174788893:role/eks-cost-project-dev-devops"
      username = "eks-cost-project-dev-devops"
    }
  ]
  aws_auth_accounts = [
    "002174788893"
  ]
}