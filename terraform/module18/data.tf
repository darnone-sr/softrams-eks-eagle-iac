data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  count = local.run ? 1 : 0
  name = module.eks[0].cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  count = local.run ? 1 : 0
  name = module.eks[0].cluster_id
}