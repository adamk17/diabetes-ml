resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name        = "${var.project_name}-vpc"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name        = "${var.project_name}-public-${count.index + 1}"
      Environment = var.environment
      Project     = var.project_name
      Type        = "public"
    },
    var.additional_tags
  )
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)

  tags = merge(
    {
      Name        = "${var.project_name}-private-${count.index + 1}"
      Environment = var.environment
      Project     = var.project_name
      Type        = "private"
    },
    var.additional_tags
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.project_name}-igw"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name        = "${var.project_name}-public-rt"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    {
      Name        = "${var.project_name}-nat-eip"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      Name        = "${var.project_name}-nat"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count  = var.create_nat_gateway && length(var.private_subnet_cidrs) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[0].id
  }

  tags = merge(
    {
      Name        = "${var.project_name}-private-rt"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_route_table_association" "private" {
  count          = var.create_nat_gateway ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table" "private_isolated" {
  count  = var.create_nat_gateway ? 0 : (length(var.private_subnet_cidrs) > 0 ? 1 : 0)
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name        = "${var.project_name}-private-isolated-rt"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}

resource "aws_route_table_association" "private_isolated" {
  count          = var.create_nat_gateway ? 0 : length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_isolated[0].id
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.project_name}-rds-sg"
      Environment = var.environment
      Project     = var.project_name
    },
    var.additional_tags
  )
}
