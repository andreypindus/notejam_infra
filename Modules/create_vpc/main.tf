# Define locals for use in current module
locals {
  max_subnet_length = max(length(var.private_subnets), length(var.public_subnets))
}

# Create new VPC
resource "aws_vpc" "new_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name = var.vpc_name
  }
}

# Create public subnet
resource "aws_subnet" "new_public_subnet" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  cidr_block              = var.public_subnets[count.index]
  vpc_id                  = aws_vpc.new_vpc.id
  map_public_ip_on_launch = var.map_public_ip_on_launch
  availability_zone       = element(var.azs, count.index)

  tags = {
    Name = var.public_subnet_names[count.index]
  }
}

# Create private subnet
resource "aws_subnet" "new_private_subnet" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  cidr_block        = var.private_subnets[count.index]
  vpc_id            = aws_vpc.new_vpc.id
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = var.private_subnet_names[count.index]
  }
}

# Create internet gateway for the VPC
resource "aws_internet_gateway" "vpc_internet_gateway" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.new_vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

# Public routes
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.new_vpc.id

  tags = {
    Name = "Public route table"
  }
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_internet_gateway[0].id
}

# Private routes
resource "aws_route_table" "private" {
  count = local.max_subnet_length > 0 ? local.max_subnet_length : 0

  vpc_id = aws_vpc.new_vpc.id

  tags = {
    Name = "Private route table"
  }
}

# Create elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc = true

  tags = {
    Name = "NAT_ip"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "new_nat_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.new_public_subnet[0].id

  tags = {
    Name = "NAT Gateway"
  }

  depends_on = [aws_internet_gateway.vpc_internet_gateway]
}

resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.new_nat_gateway[0].id
}


# Create network ACL for public subnets
resource "aws_network_acl" "public_subnet_acl" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.new_vpc.id
  subnet_ids = aws_subnet.new_public_subnet.*.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 103
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Public subnet ACL"
  }
}

# Create network ACL for private subnets
resource "aws_network_acl" "private_subnet_acl" {
  count = length(var.private_subnets) > 0 ? 1 : 0

  vpc_id     = aws_vpc.new_vpc.id
  subnet_ids = aws_subnet.new_private_subnet.*.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "Private subnets ACL"
  }
}

# Route table association
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id      = element(aws_subnet.new_private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.new_public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}