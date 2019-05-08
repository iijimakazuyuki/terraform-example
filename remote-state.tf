// At first you must create S3 bucket and DynamoDB table,
// with commenting out below remote state config:
terraform {
  backend "s3" {
    bucket         = "my-terraform-remote-state"
    key            = "remote-state"
    region         = "ap-northeast-1"
    dynamodb_table = "remote-backend-lock"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_dynamodb_table" "remote-backend-lock" {
  name           = "remote-backend-lock"
  billing_mode   = "PROVISIONED"
  hash_key       = "LockID"
  write_capacity = 1
  read_capacity  = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "admin" {
  bucket = "my-terraform-remote-state"
  acl    = "private"

  versioning {
    enabled = true
  }
}
