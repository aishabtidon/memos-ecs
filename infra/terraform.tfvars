# Project and environment
project_name = "memos"
environment  = "dev"
aws_region   = "eu-north-1"

# Domain
root_domain = "aishabtidon.org"
subdomain  = "tm"

# GitHub OIDC for CI/CD
github_org_repo = "aishabtidon/memos-ecs"
github_branch   = "main"

# Terraform state backend
terraform_state_bucket_name         = "aishabtidon-terraform-state"
terraform_state_dynamodb_table_name = "terraform-locks"
