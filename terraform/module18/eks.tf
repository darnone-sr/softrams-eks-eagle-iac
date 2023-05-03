module "eks" {
  count = local.run ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name                   = "${local.cluster_name}"
  cluster_version                = "1.24"
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true
  enable_irsa                    = true
  manage_aws_auth_configmap      = false
  create_aws_auth_configmap      = true
  create_iam_role                = true
  
  node_security_group_additional_rules ={
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

  cluster_encryption_config = [
    {
      //provider_key_arn = module.kms.arn
      provider_key_arn = local.provider_key_arn
      resources        = ["secrets"]
    }
  ]

  iam_role_path                 = "${local.path}"
  iam_role_permissions_boundary = "${local.permissions_boundary}"

  self_managed_node_groups = {
    worker_group = {
      name                       = "worker-group-${local.cluster_name}"
      instance_type              = "t3.xlarge"
      max_price                  = "0.030"
      desired_size               = 3
      max_size                   = 5
      ami_id                     = "ami-0ce0bc9be2a044a29"
      iam_role_path              = "${local.path}"
      iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
      enable_bootstrap_user_data = true
      instance_refresh_enabled   = true
      additional_security_group_ids = ""
      key_name                      = ""
      post_bootstrap_user_data   = <<EOF
useradd -U -d /home/audit_user -s /bin/bash -m audit_user || true
mkdir -p /home/audit_user/.ssh || true
echo "ssh-rsa PUBLIC_KEY_OF_AUDIT_USER" > /home/audit_user/.ssh/authorized_keys
chown -R audit_user:audit_user /home/audit_user/.ssh
chmod 0700 /home/audit_user/.ssh
chmod 0600 /home/audit_user/.ssh/authorized_keys
echo "audit_user        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers
EOF
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                   = "true"
        "k8s.io/cluster-autoscaler/eks-${local.cluster_name}" = "owned"
      }
    }
  }
}
