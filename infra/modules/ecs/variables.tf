variable "project_name" {
  type        = string

}

variable "environment" {
  type        = string
  
}

variable "aws_region" {
  type        = string
}

variable "container_name" {
  type        = string
  description = "Name of the container in the task definition"
}

variable "container_port" {
  type        = number
  description = "Port the container listens on"
}

variable "ecr_repository_url" {
  type        = string
  description = "Full ECR repository URL"
}

variable "image_tag" {
  type        = string
  description = "Image tag to deploy"
}

variable "efs_id" {
  type        = string
  description = "EFS file system ID"
}

variable "efs_access_point_id" {
  type        = string
  description = "EFS access point ID"
}

variable "efs_mount_path" {
  type        = string
  description = "Path inside the container where EFS is mounted"
  default     = "/var/opt/memos"
}

variable "environment_variables" {
  type        = list(object({ name = string, value = string }))
  description = "Environment variables for the container"
  default     = []
}

variable "task_cpu" {
  type        = number
  description = "Task CPU units (1024 = 1 vCPU). Use valid Fargate combo with task_memory."
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Task memory in MiB"
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Number of tasks to run"
  default     = 1
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 7
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Fargate tasks"
}

variable "ecs_security_group_id" {
  type        = string
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN "
}

variable "task_execution_role_arn" {
  type        = string
}

variable "task_role_arn" {
  type        = string
  default     = null
}
