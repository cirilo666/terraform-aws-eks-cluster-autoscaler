locals {
  name = "aws-cluster-autoscaler"
  asgs = distinct(flatten([
    for group in data.aws_eks_node_group.group : [
      for resource in group.resources : [
        for asg in resource.autoscaling_groups : asg.name
      ]
    ]
  ]))
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_eks_node_groups" "groups" {
  cluster_name = var.cluster_name
}

data "aws_eks_node_group" "group" {
  for_each = data.aws_eks_node_groups.groups.names

  cluster_name    = var.cluster_name
  node_group_name = each.value
}

data "aws_autoscaling_groups" "groups" {
  names = local.asgs
}

module "autoscaler_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 5"

  name        = local.name
  path        = "/eks-autoscaler/"
  description = "EKS autoscaler Policy ${local.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["${join("\", \"", data.aws_autoscaling_groups.groups.arns)}"]
    }
  ]
}
EOF

  tags = var.tags
}

module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-eks-role"
  version = "~> 5"

  role_name = local.name
  role_path = "/eks-autoscaler/"

  role_policy_arns = {
    "AmazonEKS_Autoscaler_Policy" = module.autoscaler_policy.arn
  }

  cluster_service_accounts = {
    (var.cluster_name) = [
      "kube-system:${local.name}"
    ]
  }

  tags = var.tags
}


resource "helm_release" "cluster_autoscaler" {
  name       = "aws-cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"

  cleanup_on_fail = true
  version         = "9.16.2"
  force_update    = true

  values = [
    templatefile("template.yaml",
      {
        cluster_name                     = var.cluster_name
        role_arn                         = module.iam_role.iam_role_arn
        service_account_name             = local.name
        aws_region                       = var.aws_region
        scale_down_utilization_threshold = var.scale_down_utilization_threshold
      }
    )
  ]
}
