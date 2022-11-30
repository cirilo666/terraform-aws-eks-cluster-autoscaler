module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.10.1"

  create_role = true

  role_name = local.name

  tags = var.tags

  provider_url = local.cluster_oidc_issuer

  role_policy_arns = [
    module.autoscaler_policy.arn
  ]

  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:${local.name}"]
}
