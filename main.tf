locals {
  name = "aws-cluster-autoscaler"
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
        cluster_name         = var.cluster_name
        role_arn             = module.iam_role.iam_role_arn
        service_account_name = local.name
        aws_region           = var.aws_region
      }
    )
  ]
}
