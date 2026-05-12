variable "environment" {
  description = "The environment for which to deploy the infrastructure (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "ap-south-1"
}

variable "aws_az" {
  description = "AWS Availability Zone."
  type        = string
  default     = "ap-south-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for DR VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_name" {
  description = "AWS EC2 Key Pair name."
  type        = string
}