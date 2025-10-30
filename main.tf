terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.18"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "mikecloud24_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "mikecloud24-vpc"
  }
}

resource "aws_subnet" "mikecloud24_subnet" {
  count = 2
  vpc_id                  = aws_vpc.mikecloud24_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.mikecloud24_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "mikecloud24-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "mikecloud24_igw" {
  vpc_id = aws_vpc.mikecloud24_vpc.id

  tags = {
    Name = "mikecloud24-igw"
  }
}

resource "aws_route_table" "mikecloud24_route_table" {
  vpc_id = aws_vpc.mikecloud24_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mikecloud24_igw.id
  }

  tags = {
    Name = "mikecloud24-route-table"
  }
}

resource "aws_route_table_association" "mikecloud24_association" {
  count          = 2
  subnet_id      = aws_subnet.mikecloud24_subnet[count.index].id
  route_table_id = aws_route_table.mikecloud24_route_table.id
}

resource "aws_security_group" "mikecloud24_cluster_sg" {
  vpc_id = aws_vpc.mikecloud24_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mikecloud24-cluster-sg"
  }
}

resource "aws_security_group" "mikecloud24_node_sg" {
  vpc_id = aws_vpc.mikecloud24_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mikecloud24-node-sg"
  }
}

resource "aws_eks_cluster" "mikecloud24" {
  name     = "mikecloud24-cluster"
  role_arn = aws_iam_role.mikecloud24_eks_role.arn

  vpc_config {
    subnet_ids         = aws_subnet.mikecloud24_subnet[*].id
    security_group_ids = [aws_security_group.mikecloud24_cluster_sg.id]
  }
}


resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.mikecloud24.name
  addon_name               = "aws-ebs-csi-driver"
  # Use the IRSA role we create in iam.tf so the add-on's controller pod can
  # assume it via web identity.
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  timeouts {
    create = "30m"
  }

  depends_on = [
    aws_eks_node_group.mikecloud24,
    aws_iam_role_policy_attachment.ebs_csi_driver
  ]
}
resource "aws_eks_node_group" "mikecloud24" {
  cluster_name      = aws_eks_cluster.mikecloud24.name
    node_group_name = "mikecloud24-node-group"
    node_role_arn   = aws_iam_role.mikecloud24_node_role.arn
    subnet_ids      = aws_subnet.mikecloud24_subnet[*].id
    instance_types  = ["t2.medium"]

    scaling_config {
      desired_size = 3
      max_size     = 3
      min_size     = 3
    }

    remote_access {
      ec2_ssh_key               = var.ssh_key_name
      source_security_group_ids = [aws_security_group.mikecloud24_node_sg.id]
}
}

/* IAM role and policy attachments were moved to iam.tf for better separation of concerns. */