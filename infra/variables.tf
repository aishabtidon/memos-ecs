# Project Configuration
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "memos"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}
# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-north-1a", "eu-north-1b"]
}

variable "root_domain" {
  type    = string
  default = "aishabtidon.org"
}

variable "subdomain" {
  type    = string
  default = "tm"
}

variable "image_tag" {
  type    = string
  default = "v1.0.0"
}

# Application Configuration
variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "memos"
}

variable "container_port" {
  description = "Port on which the container listens"
  type        = number
  default     = 5230
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/health"
}

# HTTPS
variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on ALB"
  type        = string
  default     = ""
}

# GitHub OIDC
variable "github_org_repo" {
  description = "GitHub org/repo for OIDC"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "Branch allowed for GitHub OIDC"
  type        = string
  default     = "main"
}

variable "terraform_state_bucket_name" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "terraform_state_dynamodb_table_name" {
  description = "DynamoDB table for Terraform lock"
  type        = string
  default     = ""
}

# IAM
variable "enable_secrets_access" {
  description = "Allow ECS execution role to read SSM/Secrets Manager"
  type        = bool
  default     = false
}

variable "secrets_arns" {
  description = "ARNs of secrets/parameters for execution role"
  type        = list(string)
  default     = []
}

variable "enable_task_role" {
  description = "Create ECS task role"
  type        = bool
  default     = false
}

variable "enable_ecs_exec" {
  description = "Allow ECS Exec"
  type        = bool
  default     = false
}

variable "enable_efs_access" {
  description = "Allow task role to access EFS"
  type        = bool
  default     = false
}

variable "enable_s3_access" {
  description = "Allow task role to read/write S3"
  type        = bool
  default     = false
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs for task role"
  type        = list(string)
  default     = []
}

variable "enable_autoscaling" {
  description = "Create IAM role for ECS Application Auto Scaling"
  type        = bool
  default     = false
}
