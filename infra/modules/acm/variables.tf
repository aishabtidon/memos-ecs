

variable "project_name" {
  type        = string
}

variable "environment" {
  type        = string
}

variable "domain_name" {
  type        = string
  description = "FQDN for the certificate"
}

variable "root_domain" {
  type        = string
  description = "Root domain used to look up the Route53 hosted zone for the validation record"
}
