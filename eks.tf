

# EKS VPC with three subnets in different availability zones
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false

  tags = {
    Name = var.cluster_name
  }
}

# Create three subnets in different availability zones
resource "aws_subnet" "eks_subnet_az_a" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_region.current.name
  tags              = { Name = "${var.cluster_name}-az-a" }
}

resource "aws_subnet" "eks_subnet_az_b" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_region.current.name_b
  tags              = { Name = "${var.cluster_name}-az-b" }
}

resource "aws_subnet" "eks_subnet_az_c" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_region.current.name_c
  tags              = { Name = "${var.cluster_name}-az-c" }
}

# Other VPC with two public subnets and three private subnets

resource "aws_vpc" "other_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Other-VPC"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.other_vpc.id
  cidr_block              = "192.168.0.0/25"
  availability_zone       = data.aws_region.current.name
  map_public_ip_on_launch = true

  tags = { Name = "Other-Public-Subnet-A" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.other_vpc.id
  cidr_block              = "192.168.0.128/25"
  availability_zone       = data.aws_region.current.name_b
  map_public_ip_on_launch = true

  tags = { Name = "Other-Public-Subnet-B" }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.other_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = data.aws_region.current.name

  tags = { Name = "Other-Private-Subnet-A" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.other_vpc.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = data.aws_region.current.name_b

  tags = { Name = "Other-Private-Subnet-B" }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.other_vpc.id
  cidr_block        = "192.168.3.0/24"
  availability_zone = data.aws_region.current.name_c

  tags = { Name = "Other-Private-Subnet-C" }
}

# EKS Cluster configuration

resource "aws_iam_role" "eks_cluster_control_plane_role" {
  name = "${var.cluster_name}-control-plane"

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
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_control_plane_role.arn

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_control_plane_policy_attachment]
}

resource "aws_iam_role" "eks_node_group_instance_profile" {
  name = "${var.cluster_name}-node-group-instance-profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "eks_nodegroup" {
  name_prefix = "${var.cluster_name}-node-group-"
  role        = aws_iam_role.eks_node_group_instance_profile.name
}

