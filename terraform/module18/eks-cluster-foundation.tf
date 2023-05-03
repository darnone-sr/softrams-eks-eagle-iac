module "eagle" {
  //source = "git@github.com:softrams-iac/terraform-k8s-cluster-foundation.git//?ref=v7.5"
  source = "../../../terraform-aws-stack-eks"

  argocd_host      = "argocd.${local.domain}"
  argocd_image     = "softrams/argocd:v2.6.3"
  domain           = local.domain
  //write_kubeconfig = false
  //create_group     = false
  target_revision  = "v6.8.0" 
  tag_subnets      = false
  /*  github_token     = jsondecode(module.data.secret-devops).github_personal-access-token
  additional_github_tokens = {
    softramsiac = jsondecode(module.data.secret-devops).github_srdevops_token
  } */

  github_token     = jsondecode(module.github_token.secret_map).argocd_github_token
  kms_key_id           = local.kms_key_id
  path                 = local.path
  permissions_boundary = local.permissions_boundary

  cluster_name              = "${local.cluster_name}"
  manage_aws_auth_configmap = true
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

  cluster_scaler_enabled    = true
  istio_enabled             = false
  kiali_enabled             = false
  dashboard_enabled         = false
  aws_lb_controller_enabled = true
  calico_enabled            = true
  eagle_config = {
    enabled = "false"
  }
  hosted_zone_id            = "${local.hosted_zone_id}"

  cluster_foundation_additional_values = <<-EOF
    metricsServer:
      targetRevision: 6.2.15
    prometheusStack:
      additionalValues:
        nodeExporter:
          enabled: false
        grafana:
          ingress:
            enabled: true
            ingressClassName: nginx-internal
            annotations:
              cert-manager.io/cluster-issuer: letsencrypt-prod
              kubernetes.io/tls-acme: "true"
            hosts:
              - grafana.${local.domain}
            tls:
              - hosts:
                  - grafana.${local.domain}
                secretName: grafana-tls
        alertmanager:
          ingress:
            enabled: true
            ingressClassName: nginx-internal
            annotations:
              cert-manager.io/cluster-issuer: letsencrypt-prod
              kubernetes.io/tls-acme: "true"
            hosts:
              - alertmanager.${local.domain}
            tls:
              - hosts:
                  - alertmanager.${local.domain}
                secretName: alertmanager-tls
          alertManagerSpec:
            web:
              httpConfig:
                headers:
                  strictTransportSecurity: "max-age=31536000; includeSubdomains; preload"
        prometheus:
          prometheusSpec:
            resources:
              limits:
                cpu: 200m
                memory: 800Mi
              requests:
                cpu: 200m
                memory: 800Mi
            web:
              httpConfig:
                headers:
                  strictTransportSecurity: "max-age=31536000; includeSubdomains; preload"
    certManager:
      additionalValues:
        podDnsConfig:
          nameservers:
            - "1.1.1.1"
            - "8.8.8.8"
    extDNS:
      aws:
        zoneType: ""
    nginx:
      additionalValues:
        controller:
          extraArgs:
            default-ssl-certificate: "prefect/prefect-tls"
    nginxInternal:
      additionalValues:
        controller:
          extraArgs:
            default-ssl-certificate: "prefect/prefect-tls"
          resources:
            requests:
              memory: "128Mi"
            limits:
              memory: "128Mi"
    cloudwatchexporter:
      enabled: false
  EOF

  /* repos = {
    cluster = {
      name = "${local.common_vars.project}-${local.common_vars.aws_environment}"
      repo = "https://github.cms.gov/iddoc/k8s-argocd-apps"
      path = "./"
      helm_config = {
        valuefiles = ["values.yaml", "values-${local.common_vars.aws_environment}.yaml"]
        values     = <<EOF
          prefect:
            roleArn: ${module.prefect-iam.role_arn}
            apollo:
              ingress:
                host: prefectapollo.${local.domain}
                tls:
                  host: prefectapollo.${local.domain}
            ui:
              apolloApiUrl: https://prefectapollo.${local.domain}/graphql
              ingress:
                host: prefectui.${local.domain}
                tls:
                  host: prefectui.${local.domain}
            postgresql:
              postgresqlPassword: ${jsondecode(module.data.secret-dba).prefect-password}
              externalHostname: prefect-dev.cluster-cqmiqbcipd3g.us-east-1.rds.amazonaws.com
        EOF
      }
    }
  } */

/*   argocd_repository_credentials = [
    {
      url    = "https://github.com/softrams-iac"
      secret = "softramsiac"
    },
    {
      url    = "https://github.cms.gov"
      secret = "argocd-github"
    }
  ] */

  argocd_repository_credentials = [
    {
      url    = "https://github.com/softrams-iac"
      secret = "argocd-github"
    }
  ]

  ext_dns_role = ({
    role_name            = "fargate-ext-dns-role"
    path                 = local.path
    permissions_boundary = local.permissions_boundary
    policy_arn           = null
    policy_name          = "fargate-ext-dns-policy"
    policy_description   = "IAM Policy to allow pod to change route53"
  })
  cert_manager_role = ({
    role_name            = "fargate-cert-manager-role"
    permissions_boundary = local.permissions_boundary
    policy_arn           = null
    policy_name          = "fargate-cert-manager-policy"
    path                 = local.path
    policy_description   = "IAM Policy to allow pod to change route53"
  })
  aws_lb_controller_role = ({
    role_name            = "fargate-aws-lb-controller-role"
    permissions_boundary = local.permissions_boundary
    policy_arn           = null
    policy_name          = "fargate-aws-lb-controller-policy"
    path                 = local.path
    policy_description   = "IAM Policy to allow lb controller to create resources"
  })
  cluster_autoscaler_role = ({
    policy_name        = "${local.cluster_name}-aws-lb-controller-policy"
    policy_description = "IAM Policy to allow cluster autoscaler to scale"
  })
}