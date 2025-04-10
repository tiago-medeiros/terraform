

# EKS VPC with three subnets in different availability zones
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false

  tags = {
    Name = var.cluster_stack
  }
}

# Create three subnets in different availability zones
resource "aws_subnet" "eks_subnet_az_a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.0.0/18"
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.cluster_stack}-az-a" }
}

resource "aws_subnet" "eks_subnet_az_b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.64.0/18"
  availability_zone = "${var.region}b"
  tags              = { Name = "${var.cluster_stack}-az-b" }
}

resource "aws_subnet" "eks_subnet_az_c" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.128.0/18"
  availability_zone = "${var.region}c"
  tags              = { Name = "${var.cluster_stack}-az-c" }
}

resource "aws_subnet" "eks_subnet_az_d" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.192.0/18"
  availability_zone = "${var.region}d"
  tags              = { Name = "${var.cluster_stack}-az-d" }
}


# Other VPC with two public subnets and three private subnets

resource "aws_vpc" "app_vpc" {
  cidr_block           = "20.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.app_stack
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "20.0.0.0/19"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.app_stack}-pub-a" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "20.0.32.0/19"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${var.app_stack}-pub-b" }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "20.0.64.0/18"
  availability_zone = "${var.region}a"

  tags = { Name = "${var.app_stack}-priv-a" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "20.0.128.0/18"
  availability_zone = "${var.region}b"

  tags = { Name = "${var.app_stack}-priv-b" }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "20.0.192.0/18"
  availability_zone = "${var.region}c"

  tags = { Name = "${var.app_stack}-priv-c" }
}

# EKS Cluster configuration

resource "aws_iam_role" "eks_cluster_control_plane_role" {
  name = "${var.cluster_stack}-control-plane"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_control_plane_policy_attachment" {
  role       = aws_iam_role.eks_cluster_control_plane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_stack
  role_arn = aws_iam_role.eks_cluster_control_plane_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks_subnet_az_a.id, aws_subnet.eks_subnet_az_b.id, aws_subnet.eks_subnet_az_c.id, aws_subnet.eks_subnet_az_d.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_control_plane_policy_attachment]
}

