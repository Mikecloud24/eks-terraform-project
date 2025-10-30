output "cluster_id" {
  value = aws_eks_cluster.mikecloud24.id
}

output "node_group_id" {
  value = aws_eks_node_group.mikecloud24.id
}

output "vpc_id" {
  value = aws_vpc.mikecloud24_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.mikecloud24_subnet[*].id
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = aws_eks_cluster.mikecloud24.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate-authority-data for the cluster"
  value       = aws_eks_cluster.mikecloud24.certificate_authority[0].data
}

output "kubeconfig" {
  description = "Kubeconfig content for the cluster (use aws eks get-token or aws eks update-kubeconfig for authentication)"
  value = <<EOT
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.mikecloud24.endpoint}
    certificate-authority-data: ${aws_eks_cluster.mikecloud24.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - "eks"
        - "get-token"
        - "--cluster-name"
        - "${aws_eks_cluster.mikecloud24.name}"
EOT
}
