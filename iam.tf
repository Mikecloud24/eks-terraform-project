// IAM roles and policy attachments extracted from main.tf

locals {
  # OIDC issuer host (without https://) used to build the IRSA condition key
  oidc_issuer_host = replace(aws_eks_cluster.mikecloud24.identity[0].oidc[0].issuer, "https://", "")
  # EBS CSI driver's controller service account used by the managed addon
  ebs_service_account = "system:serviceaccount:kube-system:ebs-csi-controller-sa"

  trust_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Federated = aws_iam_openid_connect_provider.oidc.arn }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_host}:sub" = local.ebs_service_account
          }
        }
      }
    ]
  }
}

resource "aws_iam_role" "mikecloud24_eks_role" {
  name = "mikecloud24-eks-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mikecloud24_cluster_role_policy" {
  role           = aws_iam_role.mikecloud24_eks_role.name
  policy_arn     = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "mikecloud24_node_role" {
  name = "mikecloud24-node-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "mikecloud24_node_role_policy" {
  role         = aws_iam_role.mikecloud24_node_role.name
  policy_arn   = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "mikecloud24_node_group_cni_policy" {
  role         = aws_iam_role.mikecloud24_node_role.name
  policy_arn   = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "mikecloud24_node_group_registry_policy" {
  role         = aws_iam_role.mikecloud24_node_role.name
  policy_arn   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role" "ebs_csi_driver" {
  name = "mikecloud24-ebs-csi-driver-role"

  # Trust policy for IRSA: allow the EKS cluster's OIDC provider to assume this
  # role via web identity for the add-on's service account. We scope the trust
  # to the add-on service account `ebs-csi-controller-sa` in the `kube-system`
  # namespace. This requires an OIDC provider resource (created below).

  assume_role_policy = jsonencode(local.trust_policy)
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role        = aws_iam_role.ebs_csi_driver.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


resource "aws_iam_openid_connect_provider" "oidc" {
  url              = aws_eks_cluster.mikecloud24.identity[0].oidc[0].issuer
  client_id_list   = ["sts.amazonaws.com"]
  # Common AWS EKS OIDC thumbprint; works for standard EKS OIDC providers.
  thumbprint_list  = ["9e99a48a9960b14926bb7f3b02e22da0afd2cbd6"]
}
