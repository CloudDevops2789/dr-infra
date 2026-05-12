resource "aws_instance" "dc_server" {
  ami                         = "ami-0df6756c66a86d64c"
  instance_type               = "t3.medium"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.dr_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.dc_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name        = "ec2-dc-v1"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}

resource "aws_instance" "web_server" {
  ami                         = "ami-0ffe8a1b305650410"
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.dr_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  tags = {
    Name        = "webserver-ad-ready-v2"
    Environment = var.environment
    Project     = "dr-poc"
    ManagedBy   = "terraform"
  }
}