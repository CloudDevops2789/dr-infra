# ------------------------
# VPC
# ------------------------
resource "aws_vpc" "dr_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "dr-${var.environment}-vpc"
  }
}

# ------------------------
# Public Subnet
# ------------------------
resource "aws_subnet" "dr_subnet" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "dr-${var.environment}-public-subnet"
  }
}

# ------------------------
# Internet Gateway
# ------------------------
resource "aws_internet_gateway" "dr_igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name = "dr-${var.environment}-igw"
  }
}

# ------------------------
# Route Table
# ------------------------
resource "aws_route_table" "dr_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }

  tags = {
    Name = "dr-${var.environment}-rt"
  }
}

# ------------------------
# Associate Route Table
# ------------------------
resource "aws_route_table_association" "dr_rta" {
  subnet_id      = aws_subnet.dr_subnet.id
  route_table_id = aws_route_table.dr_rt.id
  tags = {
    Name = "dr-${var.environment}-rta"
  }
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "dr_sg" {
  vpc_id = aws_vpc.dr_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "dr-${var.environment}-sg"
  }
}

# ------------------------
# EC2 Instance
# ------------------------
resource "aws_instance" "dr_server" {
  ami           = "ami-07216ac99dc46a187" # Ubuntu 22.04 (verify region)
  instance_type = "t3.micro"
  key_name      = "aws_dr_key"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  subnet_id              = aws_subnet.dr_subnet.id
  vpc_security_group_ids = [aws_security_group.dr_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "dr-${var.environment}-server"
  }
}