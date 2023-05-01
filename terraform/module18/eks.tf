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
  
  //hosted_zone_id            = "Z05906142LVNI5Q6K6QI2" //cluster foundation

  cluster_encryption_config = [
    {
      provider_key_arn = module.kms.arn
      resources        = ["secrets"]
    }
  ]

  iam_role_path                 = "${local.path}"
  iam_role_permissions_boundary = "${local.permissions_boundary}"

  self_managed_node_groups = {
    worker_group = {
      name                       = "worker-group-${local.cluster_name}"
      instance_type              = "t3.large"
      max_price                  = "0.030"
      desired_size               = 2
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
