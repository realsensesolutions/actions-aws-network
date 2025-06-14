# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  assign_generated_ipv6_cidr_block = true

  tags = merge(local.tags, {
    Name = "${var.instance}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.instance}-igw"
  })
}

# Egress-Only Internet Gateway for IPv6 outbound traffic
resource "aws_egress_only_internet_gateway" "main" {
  count  = var.enable_egress_only_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.instance}-eoigw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                            = 2
  vpc_id                           = aws_vpc.main.id
  cidr_block                       = "10.0.${count.index * 16}.0/20"
  ipv6_cidr_block                  = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)
  availability_zone                = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch          = true
  assign_ipv6_address_on_creation  = true

  tags = merge(local.tags, {
    Name = "${var.instance}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count                           = 2
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.${32 + count.index * 16}.0/20"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 2)
  availability_zone               = data.aws_availability_zones.available.names[count.index]
  assign_ipv6_address_on_creation = true

  tags = merge(local.tags, {
    Name = "${var.instance}-private-subnet-${count.index + 1}"
    Type = "private"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? 1 : 0
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.tags, {
    Name = "${var.instance}-nat-eip"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(local.tags, {
    Name = "${var.instance}-nat-gateway"
  })
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.instance}-public-rt"
  })
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.instance}-private-rt"
  })
}

# IPv4 route through NAT Gateway (conditional)
resource "aws_route" "private_ipv4_nat" {
  count                  = var.enable_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# IPv6 route through Egress-Only Internet Gateway (conditional)
resource "aws_route" "private_ipv6_egress" {
  count                       = var.enable_egress_only_gateway ? 1 : 0
  route_table_id              = aws_route_table.private.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.main[0].id
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Association for Private Subnets
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Public Security Group - allows all inbound and outbound traffic
resource "aws_security_group" "public" {
  name_prefix = "${var.instance}-public-"
  vpc_id      = aws_vpc.main.id
  description = "Public security group for ${var.instance}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "udp"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.instance}-public-sg"
    Type = "public"
  })
}

# Private Security Group - allows traffic only within VPC
resource "aws_security_group" "private" {
  name_prefix = "${var.instance}-private-"
  vpc_id      = aws_vpc.main.id
  description = "Private security group for ${var.instance}"

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  ingress {
    from_port        = 0
    to_port          = 65535
    protocol         = "udp"
    ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.instance}-private-sg"
    Type = "private"
  })
}