terraform {
  backend "s3" {
    bucket         = "dr-terraform-state-storage-test"
    key            = "dr-poc/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-lock"
  }
}