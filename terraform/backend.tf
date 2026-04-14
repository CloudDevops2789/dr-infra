terraform {
  backend "s3" {
    bucket         = "dr-terraform-state-storage"
    key            = "dr-infra/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}
