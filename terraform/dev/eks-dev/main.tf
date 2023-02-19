module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.cluster_name
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
  # Required for Karpenter role below
  enable_irsa = true

  # node_security_group_additional_rules = {
  #   ingress_nodes_karpenter_port = {
  #     description                   = "Cluster API to Node group for Karpenter webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 8443
  #     to_port                       = 8443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  # }
  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.cluster_name
  }
  # EKS Managed Node Group(s)

  eks_managed_node_groups = {
    karpenter_node = {
      instance_types = ["t3.medium"]
      # Not required nor used - avoid tagging two security groups with same tag as well
      create_security_group = false

      # Ensure enough capacity to run 2 Karpenter pods
      min_size     = 2
      max_size     = 3
      desired_size = 2

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "KarpenterOnly"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.6.0"

  cluster_name = module.eks.cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # Since Karpenter is running on an EKS Managed Node group,
  # we can re-use the role that was created for the node group
  create_iam_role = false
  iam_role_arn    = module.eks.eks_managed_node_groups["karpenter_node"].iam_role_arn
  tags            = local.tags

  # Do not add depend on . 
  # If add depends_on and then get error message.
  # depends_on = [module.eks]
}




# aws-auth configmap
# manage_aws_auth_configmap = false

# aws_auth_users = [
#   {
#     groups   = ["system:masters"]
#     userarn  = "arn:aws:iam::002174788893:user/EleSangwon-dev"
#     username = "eks-cost-project-dev-devops"
#   }
# ]

# aws_auth_roles = [
#   {
#     groups   = ["system:masters"]
#     rolearn  = "arn:aws:iam::002174788893:role/eks-cost-project-dev-devops"
#     username = "eks-cost-project-dev-devops"
#   }
# ]
# aws_auth_accounts = [
#   "002174788893"
# ]


