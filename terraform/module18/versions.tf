terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket         = "4i-init-582830503829-terraform-state"
    key            = "4i-init/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "4i-terraform-state-init-lock"
    encrypt        = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.5.0"
    }
    k8s = {
      source  = "banzaicloud/k8s"
      version = ">= 0.8.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.0"
    }
  }
}

provider "k8s" {
  load_config_file       = "false"
  host                   = local.run ? module.eks[0].cluster_endpoint : "https://not_used.local"
  token                  = local.run ? data.aws_eks_cluster_auth.cluster[0].token : "not_used"
  cluster_ca_certificate = local.run ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : base64decode(local.fake_cert)
}

provider "kubernetes" {
  host                   = local.run ? module.eks[0].cluster_endpoint : "https://not_used.local"
  token                  = local.run ? data.aws_eks_cluster_auth.cluster[0].token : "not_used"
  cluster_ca_certificate = local.run ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : base64decode(local.fake_cert)
}

provider "helm" {
  kubernetes {
    host                   = local.run ? module.eks[0].cluster_endpoint : "https://not_used.local"
    token                  = local.run ? data.aws_eks_cluster_auth.cluster[0].token : "not_used"
    cluster_ca_certificate = local.run ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : base64decode(local.fake_cert)
  }
}