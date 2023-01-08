terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "eks-cost-project-tfstates-dev"
    key            = "eks-cost-project-tfstates-dev/eks-cost-project-eks-helm-dev.tfstate"
    profile        = "EleSangwon-dev"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "EleSangwon-dev"
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket         = "eks-cost-project-tfstates-dev"
    region         = "ap-northeast-2"
    key            = "eks-cost-project-tfstates-dev/eks-cost-project-eks-dev.tfstate"
    profile        = "EleSangwon-dev"
    dynamodb_table = "terraform-lock"
  }
}

locals {
  name = "eks-cost-project-dev"
  tags = {
    Name        = local.name
    Environment = "dev"
    Team        = "devops"
    Project     = "eks-cost-project"
  }
  profile          = "EleSangwon-dev"
  eks              = data.terraform_remote_state.eks.outputs.eks
  provider_url     = local.eks.oidc_provider
  eks_cluster_name = local.eks.cluster_name
}

module "base_services" {
  source = "git@github.com:devops-sangwon/terraform-modules.git//modules/helm"

  name             = local.name
  tags             = local.tags
  provider_url     = local.provider_url
  eks_cluster_name = local.eks_cluster_name
  output_eks       = local.eks
  profile          = local.profile
}