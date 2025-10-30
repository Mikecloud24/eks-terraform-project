# IRSA (IAM Roles for Service Accounts) for EBS CSI driver

This project configures the EBS CSI driver using IRSA so the add-on's controller
pod can assume a dedicated IAM role with the minimal permissions needed to
manage EBS volumes.

What we create

- An `aws_iam_openid_connect_provider` pointing to the EKS cluster OIDC issuer.
- An IAM role (`mikecloud24-ebs-csi-driver-role`) whose trust policy allows
  `sts:AssumeRoleWithWebIdentity` only for the add-on controller's service
  account: `system:serviceaccount:kube-system:ebs-csi-controller-sa`.
- The role is attached to the managed AWS policy `AmazonEBSCSIDriverPolicy`.

Why this matters

- Using IRSA is recommended because it scopes permissions to a single service
  account instead of broad node IAM permissions.
- The managed EKS add-on for the driver will use the provided
  `service_account_role_arn` so the controller pod can call AWS APIs.

If you change the service account name or namespace used by the addon, update
the IAM role trust condition in `iam.tf` accordingly.

Troubleshooting

- If the add-on shows `CREATING` for a long time, check:
  - `aws eks describe-addon --cluster-name mikecloud24-cluster --addon-name aws-ebs-csi-driver`
  - `kubectl -n kube-system get pods` and check the `ebs-csi-controller` pods for errors.
- If you see permission or web-identity errors in pod logs, ensure the OIDC
  provider exists and the role trust policy includes the correct issuer host
  and service account `sub` condition.
