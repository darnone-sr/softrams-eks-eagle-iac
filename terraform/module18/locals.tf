locals {
  // Cluster Vars
  project              = "4i"
  environment          = "init"
  cluster_name         = "${local.project}-${local.environment}"
  vpc_name             = "${local.project}-${local.environment}-vpc"
  aws_account_number   = "582830503829"
  region               = "us-east-1"
  path                 = "/delagatedadmin/developer/"
  permissions_boundary = ""
  provider_key_arn     = module.kms.arn

  // Provider Vars
  run       = true
  fake_cert = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJek1ETXlNREl6TURRME5sb1hEVE16TURNeE56SXpNRFEwTmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTVVwCkdKQ1RXKzN0cThUSmZ1SDE1SXpZVk5sYncwQy8vNmRtVmxIQ2x4Y0czK3BpVzhLd0pDeGVaYnhsUllnVnN0RUsKTUpCUnpEdEVST0dKclRFWDJMWUUxbHJGR2tsaUpzU09wUmpxckJjOUlIV24yYjFGdnNXRUVzdjlOMGE2NGh1UQpsUnVobmhLOTA3azhjRlExUEVwVHZDZ0xSSmtKREtyTjVPdzNTQW12cXlMNUJtc1o1TmM0WUR3dUpRa21hVG5ICmhOMHNvUnFKSVJTQW9sNkV5SVBhNnhQV0N5SWhHak5WTkt1dUhXZnBsRDZGRmgyRUV0QmIxRXJXMWprc0xzMEwKQkRDTU5ZSFg2K1ZhVG5OeG1Gc0MxZ0Y1MHlyN3B1UnI4R1NpMG42Z1FmMytFMVBqakZ4VHJDV1pnZTBEQVFzWQpLaDM5WTBieENyQ2dSWXlMVXowQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZHUlpRS0dGbW1CS2tMU2hGOGR3alNMZG1BT3hNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBTDB5aEViOXdNdXQwaWJqS2VXZwo3aDFjY0JtWWRBZjFaZEZhVFVtUkh3SXV6Z1E0dzI0aDlQcWxzSkhiRWxhR3ZSRmFPUm1TVTZGZTNadUhRZDg0Cm00eVIxcEV2UnhDcmEwVUJxRHlPN0luSjdkemVuK2ZUb1pCN2o4aDcyalhpbWZ3ZDc2Vi9xUWdEN3ZDTDc3OXoKZVp2Z0pTMjRxZGdyM3o4SkI2Z01LVllzUEZ3cTdQU0tjN1RaUFZZZU5COVRqOHRqeExUTFdKTHJSVWxEZ3IvUQpsdGVvSC9JNzB5ckg3Zll6K08zTHh6NGVGVlMxRGNocDNSY1hwVUhmK0JKcHBnNUovWXY1SS9SNXVwcmNiRW05CkhRcFByZ3JIb2JjTC9JeG02RzJtUE5RZUdacWpsUlV4cGIrQjBLdmdINGhGc0kxeWtTSklzbGo3RUFmUHpEUzgKTU4wPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="

  // Eagle Vars
  domain         = "iactesting.softrams.cloud"
  hosted_zone_id = "Z05906142LVNI5Q6K6QI2"

  // EKS Vars
  kms_key_id                = module.kms.id
  cluster_oidc_issuer_url   = module.eks[0].cluster_oidc_issuer_url
  cluster_oidc_provider_arn = module.eks[0].oidc_provider_arn
  eks_cluster_id            = module.eks[0].cluster_id
  eks_cluster_endpoint      = module.eks[0].cluster_endpoint
  cert_auth_data            = data.aws_eks_cluster.cluster[0].certificate_authority[0].data
  cluster_server            = data.aws_eks_cluster.cluster[0].endpoint
  cluster_server_token      = data.aws_eks_cluster_auth.cluster[0].token
  eks_managed_node_groups   = module.eks[0].eks_managed_node_groups
  self_managed_node_groups  = module.eks[0].self_managed_node_groups
  fargate_profiles          = module.eks[0].fargate_profiles


  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_all = {
      description                   = "Cluster API to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}