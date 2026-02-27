variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "public_subnet_ids" {
  type        = list(string)
}

variable "alb_security_group_id" {
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "health_check_path" {
  description = "Path for ALB health checks"
  type        = string
}

variable "enable_https" {
  description = "If true, create HTTPS listener and redirect."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN"
  type        = string
  default     = ""
}
