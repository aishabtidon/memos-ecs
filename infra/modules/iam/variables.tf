# IAM module variables

variable "project_name" {
  type        = string
  
}

variable "environment" {
  type        = string
  
}

variable "aws_region" {
  type        = string
  
}

variable "ecr_repository_arn" {
  type        = string
  description = "ARN of the ECR repository"
}

# GitHub OIDC


variable "github_org_repo" {
  type        = string
  description = "GitHub org/repo for OIDC trust"
  default     = ""
}

variable "github_branch" {
  type        = string
  description = "Branch allowed to assume the GitHub Actions role "
  default     = "main"
}

variable "terraform_state_bucket_name" {
  type        = string
  description = "S3 bucket name for Terraform state"
  default     = ""
}

variable "terraform_state_dynamodb_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state lock"
  default     = ""
}
