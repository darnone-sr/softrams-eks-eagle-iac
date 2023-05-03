data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  count = local.run ? 1 : 0
  name  = module.eks[0].cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = local.run ? 1 : 0
  name  = module.eks[0].cluster_id
}

module "github_token" {
  source    = "git@github.com:softrams-iac/terraform-aws-data-sm-legacy.git//?ref=v1.0.5"
  secret_id = "arn:aws:secretsmanager:us-east-1:582830503829:secret:argocd_github_token-GXtXz3"
}