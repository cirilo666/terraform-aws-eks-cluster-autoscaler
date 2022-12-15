variable "cluster_name" {
  type        = string
  description = "EKS Cluster name."
}

variable "tags" {
  type        = map(string)
  description = "AWS Tags."
}

variable "aws_region" {
  type        = string
  description = "The AWS region the autoscaler will be running in."
}
