# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "dr_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "dr-vpc-${var.environment}"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}

# -------------------------
# Public Subnet
# -------------------------
resource "aws_subnet" "dr_public_subnet" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.aws_az
  map_public_ip_on_launch = true

  tags = {
    Name        = "dr-public-subnet-${var.environment}"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "dr_igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name        = "dr-igw-${var.environment}"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}

# -------------------------
# Public Route Table
# -------------------------
resource "aws_route_table" "dr_public_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }

  tags = {
    Name        = "dr-public-rt-${var.environment}"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}

# -------------------------
# Route Table Association
# -------------------------
resource "aws_route_table_association" "dr_public_assoc" {
  subnet_id      = aws_subnet.dr_public_subnet.id
  route_table_id = aws_route_table.dr_public_rt.id
}