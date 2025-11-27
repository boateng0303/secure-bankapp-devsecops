terraform {
  backend "s3" {
    bucket         = "banking-app-terraform-state-staging"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-staging"
  }
}

