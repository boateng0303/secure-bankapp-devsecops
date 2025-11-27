terraform {
  backend "s3" {
    bucket         = "banking-app-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dev"
    
    # Enable state locking
    # Create the S3 bucket and DynamoDB table before running terraform init
  }
}

