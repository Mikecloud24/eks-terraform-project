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
