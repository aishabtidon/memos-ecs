terraform {
  backend "s3" {
    bucket         = "aishabtidon-terraform-state"
    key            = "memos/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
