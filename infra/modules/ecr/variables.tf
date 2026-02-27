variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Scan images for vulnerabilities when they are pushed to the repository"
  type        = bool
  default     = true
}
