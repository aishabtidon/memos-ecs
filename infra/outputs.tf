# networking Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "github_actions_role_arn" {
  description = "ARN for GitHub Actions OIDC"
  value       = module.iam.github_actions_role_arn
}
