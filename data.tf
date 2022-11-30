data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

locals {
  cluster_oidc_issuer = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

module "autoscaler_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4"

  name        = local.name
  path        = "/autoscaler_policy/"
  description = "autoscaler Policy ${local.name}"

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
        "Resource": ["*"]
        }
    ]
}
EOF
}
