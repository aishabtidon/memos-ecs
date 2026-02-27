output "file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.main.id
}

output "file_system_arn" {
  description = "EFS file system ARN"
  value       = aws_efs_file_system.main.arn
}

output "access_point_id" {
  description = "EFS access point ID"
  value       = aws_efs_access_point.memos.id
}
