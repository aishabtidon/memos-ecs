variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "container_port" {
  type        = number
}
