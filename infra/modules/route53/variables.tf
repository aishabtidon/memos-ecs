variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  type        = string
  description = "Root domain name"
}

variable "subdomain" {
  type        = string
  description = "Subdomain for the app"
}

variable "alb_dns_name" {
  type        = string
  description = "ALB DNS name"
}

variable "alb_zone_id" {
  type        = string
  description = "ALB hosted zone ID"
}