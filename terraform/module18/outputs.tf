output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks[0].cluster_id
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks[0].cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane."
  value       = module.eks[0].cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.cluster_name
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster."
  value       = module.eks[0].cluster_iam_role_name
}

output "cluster_ca_certificate" {
  description = "K8s cluster ca certificate"
  value       = base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data)
}

output "cluster_identity_oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.eks[0].cluster_oidc_issuer_url
}

output "cluster_identity_oidc_issuer_arn" {
  description = "The ARN of the OIDC issuer"
  value       = module.eks[0].oidc_provider_arn
}