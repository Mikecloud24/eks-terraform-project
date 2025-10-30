## Terraform script to deploy AWS infra:

- AWS VPC and the associated components
- EKS cluster
- Cluster and node security groups
- EBS CSI driver
- Scaling configuration
- Cluster IAM role and policy configurations and attachment

 
## Getting kubeconfig for the EKS cluster

After you run `terraform apply` and the cluster is created, you can configure kubectl with either the AWS CLI or with the kubeconfig output.

Using the AWS CLI (recommended):

```powershell
# updates your local kubeconfig to talk to the new cluster (uses your AWS credentials)
aws eks update-kubeconfig --region us-east-1 --name mikecloud24-cluster
```

Or use the `kubeconfig` output (contains the cluster endpoint and CA) and authenticate using `aws eks get-token` as the exec plugin.

```powershell
# example: write kubeconfig to file
terraform output -raw kubeconfig > ./kubeconfig
export KUBECONFIG=./kubeconfig
# then use kubectl as usual
kubectl get nodes
```

Note: The AWS CLI method is simpler because it sets up auth using your current AWS credentials and the EKS token provider.

## EBS CSI driver (notes & verification)

During provisioning the EBS CSI driver this project uses IRSA (IAM Roles for Service Accounts).
The Terraform configuration creates an OIDC provider for the cluster and an IAM role scoped to the
EBS CSI add-on service account so the controller can assume the role via web-identity.

Quick verification (PowerShell):

```powershell
# ensure kubectl talks to the cluster
aws eks update-kubeconfig --region us-east-1 --name mikecloud24-cluster

# check the managed add-on status
aws eks describe-addon --cluster-name mikecloud24-cluster --addon-name aws-ebs-csi-driver --region us-east-1 --output json

# check in-cluster pods and logs
kubectl get pods -n kube-system | Select-String -Pattern "ebs|csi" -SimpleMatch
kubectl -n kube-system describe pod <ebs-csi-pod-name>
kubectl -n kube-system logs <ebs-csi-pod-name> -c <container-name>
```

If the add-on is ACTIVE you should see the ebs csi controller pods running in `kube-system`.

Testing dynamic provisioning (example): create a PVC that uses the default EBS storage class and verify a PV is created and bound.

Fallback: install via Helm
- If you prefer not to use the managed EKS add-on, you can remove the resource from Terraform state and install the
	upstream Helm chart. Example sequence (PowerShell):

```powershell
# delete managed addon (if currently stuck)
aws eks delete-addon --cluster-name mikecloud24-cluster --addon-name aws-ebs-csi-driver --region us-east-1

# remove from terraform state so TF won't try to recreate/manage it
terraform state rm aws_eks_addon.ebs_csi_driver

# install via Helm
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system --create-namespace
```

Notes
- The Terraform config in this repo now creates an OIDC provider and an IRSA role for the EBS CSI driver. If you
	change the service account name/namespace used by the addon, update the role trust policy accordingly.
- Be careful when re-applying Terraform if the addon is partially created — Terraform may replace the add-on which
	can purge previous configuration; inspect the EKS console add-on events for any errors before forcing changes.