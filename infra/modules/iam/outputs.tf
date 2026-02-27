# IAM module outputs

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role "
  value       = aws_iam_role.ecs_task_execution.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role "
  value       = var.github_org_repo != "" ? aws_iam_role.github_actions[0].arn : null
}
