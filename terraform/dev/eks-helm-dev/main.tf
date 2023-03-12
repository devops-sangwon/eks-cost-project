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

provider "aws" {
  region  = "ap-northeast-2"
  profile = "EleSangwon-dev"
  alias   = "EleSangwon-dev"
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
  # domain_acm       = "arn:aws:acm:ap-northeast-2:002174788893:certificate/f56f4ce7-0c36-493f-b2cf-c9cc4944faa0"
}

module "base_services" {
  source = "git@github.com:devops-sangwon/terraform-modules.git//modules/helm?ref=master"

  name               = local.name
  tags               = local.tags
  provider_url       = local.provider_url
  eks_cluster_name   = local.eks_cluster_name
  output_eks         = local.eks
  profile            = local.profile
  external_dns_zones = ["elesangwon.com"]
  # vault_domain       = "vault-dev.elesangwon.com"
  # kubecost_domain    = "cost-analyzer-dev.elesangwon.com"
  external_dns_kubecost_hostname = "cost-analyzer-dev.elesangwon.com"

  ## WIP
  # kubernetes_dashboard_domain = "eks-dev-dashboard.elesangwon.com"
  # domain_acm                  = local.domain_acm
  providers = {
    aws.dev = aws.EleSangwon-dev
  }
}