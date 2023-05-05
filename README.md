# softrams-eks-eagle-iac
This repo captures a working example of how to deploy an EKS/Eagle cluster with the two modules separated. Starting with version 12 of the terraform-aws-stack-eks stack,the EKS module implementation is now local to downstream program repos. In addition, another terraform file is requried to call the stack which deploys Eagle.

This repo contains code to store Terraform state remotely using S3 and DynamoDB. If not already in place, change directory to `terraform/remote-state` and excute the following. If necesary, modify the values in `main.tf` to made the AWS resource names unique.

```
terraform init
terraform plan
terraform apply
```

Afterwards, change the values to properly reflect the locatinon of state and to make the cluster name(s) and resource unique. To deploy the cluster, change directory to `terraform/module18` and execute:

```
terraform init
terraform plan
terraform apply
```
  
## Migrating Across v10, v11 to v12 of the Eagle Stack
When moving to v12 of the terraform-aws-stack-eks stack there are two options - creating or rebuilding a new EKS cluster with Eagle or migrating an existing cluster. For the former, the task is simply to follow the instructions below. Migration for clusters built using the stack v9.0.2 or older is a much more complicated scenario. It requires manipulation of terrafrom state, and removal of old AWS resources after migration. For migration, the first step is to move your cluster to v10 or v11 of the stack. Instructions for doing this are detailed on the migration18 example in the stack examples. Once converted to v11 of the stack, the process is to change your EKS module to only deploy EKS and add a new terraform Eagle module to call the stack.

## Terraform State
Before applying the new cluster design in a migration scenario, terraform state moves are required to reflect new locations.  For eample, with an EKS module called eks and an Eagle module called eagle.

**EKS**
`module.eks.aws_eks_cluser.this[0]` will now be `module.eks[0].aws_eks_cluster.this[0]`

**EAGLE**
`module.cluster_foundation[0].helm_release.argocd` will now be `module.eagle.module.cluster_foundation[0].helm_release.argocd`

Names will be determined on the name of the modules utilized and should be standardized to use `eks` nad `eagle`. An exhausted list will be proveded elsewhere.

## EKS Module
The EKS module now only requires variables unique to EKS and calls the [AWS EKS Terraform module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/18.31.2) directly. The implemention here is based upon verion 18.31.2 of the AWS EKS Terraform module. 

One of the new features, the main reason why EKS was removed from the stack, was so a count can be placed on the EKS module. 4i (IDDOC) has 40 plus developer environments (workspaces). An EKS cluster is not needed in all those workspaces except for the main dev workspace. With the old design it was not possible to control this because the providers are not in the repo. So, in the new module there is a count:

```
count   = local.run ? 1 : 0
```

This value is static here but in 4i there are conditions to check the workspace. The providers in a local `versions.tf` now have conditionals around them to only run if the `local.run` is set to true and not do anything otherwise.

For example

```
provider "k8s" {
  load_config_file       = "false"
  host                   = local.run ? module.eks[0].cluster_endpoint : "https://not_used.local"
  token                  = local.run ? data.aws_eks_cluster_auth.cluster[0].token : "not_used"
  cluster_ca_certificate = local.run ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : base64decode(local.fake_cert)
}

// kubernetes and helm providers excluded for brevity.
```

For this to work, a fake non-valid cert `fake_cert` is defined for when the condition is false.

**Note:** `versions.tf` has been removed from the stack and needs to be included in downstream program repo. In addition, data values `aws_eks_cluster` and `aws_eks_cluster_auth` for the cluster have also been removed from the stack and alo need to be placed in the downstream program repo. The should also be wrapped the same count as used in the EKS module.

 Variable | Type | Description | Example |
|------|---------|-----|-------|
| cluster_name | string | The name of the EKS cluster. | "4i-init" |
| cluster_version | string | The major version of Kubernetes. | "1.24" |
| vpc_id | string | The id of the VPC. | "vpc-XXXXXXXXXXXXXXXX" or module.vpc.vpc_id |
| subnet_ids | list(string) | List of private subnet ids. | ["subnet-XXXXXXXXXXXXXXXXX","subnet-XXXXXXXXXXXXXXXXX"] or module.vpc.private_subnets |
| cluster_endpoint_public_access | bool | Enable public access to the k8s api-server endpoint. | true |
| enable_irsa | bool | Enable the IODC identity provider. | true |
| manage_aws_auth_configmap | bool | Allows the EKS module to manage the aws_auth ConfigMap. | false |
| create_aws_auth_configmap | bool | Allows the EKS module to create the aws_auth ConfigMap. | true |
| create_iam_role | bool | Creates an IAM role for the cluster. | true |
| iam_role_path | string | Path in the IAM role of the cluster and worker nodes. | "/delagatedadmin/developer/" |
| iam_role_permissions_boundary | strings | Define the maxinum allowable permissions delegatd to users & groups. | "" |
| node_security_group_additional_rules | any | Defines a security group that permits node to node communication, all egress from nodes, cluster API to all ports and protocols on nodes. | SEE BELOW |
| cluster_encryption_config | list(map) | Sets the KMS key for cluster encryption. | SEE BELOW |
| self_managed_node_groups | any | List of self managed work node groups. | SEE BELOW |


## Eagle Module
In  v11 and lower of the terraform-aws-stack stack, the child EKS module included properties that were consumed by the cluster-foundation module. Now these properties need to be extracted and placeed in a new child module that calls the stack. Also, there are EKS module outputs that will need to pass to the parent module since they are referenced by Eagle. 


### ArgoCD Vars
 Variable | Type | Description | Example |
|------|---------|-----|-------|
| domain | string | The name of the domain for the hosted zone. | "iactesting.softrams.cloud" |
| hosted_zone_id | string | The ID of the hosted zone. | "ZXXXXXXXXXXXXXXXXXXXX" |
| argocd_host | string | The host of the ArgoCD Server. | "argocd.${var.domain}" |
| argocd_image | string | The image of the ArgoCD server to use. | "softrams/argocd:v2.6.3" |
| target_revision | bool | The version of the ArgoCD helm chart to use. | "v6.8.0" |
| tag_subnets | bool | Enable the tagging of subnets for auto-scaling and load balancing. | true if pre-existing, false if tagged in the VPC module. |
| cluster_scaler_enabled | bool | Deploy the cluster-autoscaler Helm chart using ArgoCD. | true |
| istio_enabled | bool | Deploy the istio Helm chart using ArgoCD. | false |
| kiali_enabled | bool | Deploy the kiali Helm chart using ArgoCD. | false |
| dashboard_enabled | bool | Deploy the kubernetes-dashboard Helm chart using ArgoCD. | false |
| aws_lb_controller_enabled | bool | Deploy the AWS Load Balancer Controller Helm chart using ArgoCD. | true |
| calico_enabled | bool | Deploy the calico Helm chart using ArgoCD. | true |
| eagle_config | map(string) | Configure database and network share parameters for ArgoCD. | enabled = true |
| github_token | string | The git hub token to use to allow ArgoCD to authenicated to GitHhub. | jsondecode(module.github_token.secret_map).argocd_github_token for a secret named argocd_github_token |
| cluster_foundation_additional_values | string | Values that override ArgoCD configuration defaults mostly involving domain values. | See code examples |
| ext_dns_role | list(any) | Credentials for argo to access repos. | See code examples. |
| argocd_repository_credentials | map(any) | Map of values for external dns role.. | See code examples. |
| cert_manager_role | map(any) | Map of values for cert manager role. | See code examples. |
| aws_lb_controller_role | map(any) | Map of values for aws lb controller role. | See code examples. |
| cluster_autoscaler_role | map(any) | Map of values for cluster autoscaler role. | See code examples. |

There may be additional roles required depending on what is enabled. Refer to terraform-aws-stack documentation all the available roles.

### EKS Module Vars for Eagle
Variable | Type | Description | Example |
|------|---------|-----|-------|
| kms_key_id | string | KMS key id for encryption. | With a KMS module, module.kms.id |
| path | string | iam_role_path passed as path. Path in the IAM role of the cluster and worker nodes.. | "
| permissions_boundary | string | iam_permissions_boundary passed as permissions_boundary. Define the maxinum allowable permissions delegatd to users & groups. | "/delagatedadmin/developer/" |
| cluster_name | string | The name of the EKS cluster. | "4i-init" |
| manage_aws_auth_configmap | bool | Allows the Eagle module to manage the aws_auth ConfigMap. | true |
| cluster_oidc_issuer_url | string | The OIDC issuer URL of the cluster. | module.eks[0].cluster_oidc_issuer_url |
| cluster_oidc_provider_arn | bool | The OIDC provider ARN of the cluster. | module.eks[0].oidc_provider_arn |
| eks_cluster_id | string | The id of the EKS cluster. | true |
| eks_cluster_endpoint | string | The endpoint of the EKS cluster API server. | module.eks[0].cluster_endpoint |
| cert_auth_data | string | The EKS cluster authentication certificate. | data.aws_eks_cluster.cluster[0].certificate_authority[0].data |
|  cluster_server  | string | The cluster server endpoint. | data.aws_eks_cluster.cluster[0].endpoint |
| cluster_server_token | string | The cluster server endpoint. | a.aws_eks_cluster_auth.cluster[0].token |
| eks_managed_node_groups | map(any) | Map of map of self managed node groups to create. | module.eks[0].eks_managed_node_groups |
| self_managed_node_groups | map(any) | Map of maps of eks managed node groups to create. | module.eks[0].self_managed_node_groups |
| fargate_profiles | string | A map of maps of fargate profiles to create. | module.eks[0].fargate_profiles |


## Roles and Paths
Version 18 of the AWS EKS Terraform module no longer supports the stripping of paths in the bootstrapper roles needed by the aws_auth ConfigMap. If paths are not needed dedfined with `iam_role_path = ""`, the worker nodes will attach to the cluster. However, if there is a requirement that roles have paths (such as CMS), the worker nodes will not attach to the cluster. The functionallity to do so in encapsulated in the terraform-aws-stack-eks stack. There are two scenarios:

### No Paths
There in nothing to set.

### With Paths
In the EKS module set

```
iam_role_path = "<some-path>"
create_aws_auth_configmap = true
manage_aws_auth_configmap = false
```
In the Eagle module set

```
manage_aws_auth_configmap = true
```
`some-path` must have leading and trailing `/`.

## Security Group Rules
Version 11 and lower of the terraform-aws-stack-eks stack encapulated the creation of a securoty group rules that allowed node to node comunication between all worker nodes, all egress on worker nodes, and cluster API to worker node on all ports and protocols. The implementation allow users to send in additional security groups if needed. Now that the EKS module is defined in the down stream module, security groups rules need to be explicitly defined. Refer to the examples for the configuration.

Add additional security group rules here if they are needed.

## Cluster Encryption Config
There is no change to this. Refer to the examples for the configuration.

## Self Managed Node Groups
There is no change to self_managed_node_groups. If you add the following inside of `worker_groups`:

```
iam_role_additional_policies  = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
``` 

It will allow one to connect to the worker nodes using Systems Manager without the need for a SSH key pair. Refer to the examples forthe congifuration.
