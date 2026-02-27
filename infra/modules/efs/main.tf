# efs module
resource "aws_efs_file_system" "main" {
  creation_token = "${var.project_name}-${var.environment}-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }


  tags = {
    Name        = "${var.project_name}-${var.environment}-efs"
    Environment = var.environment
  }
}
# EFS mount target per private subnet
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}

# Access point
resource "aws_efs_access_point" "memos" {
  file_system_id = aws_efs_file_system.main.id

  root_directory {
    path = "/memos-data"
    creation_info {
      owner_uid   = 10001
      owner_gid   = 10001
      permissions = "0755"
    }
  }

  posix_user {
    uid = 10001
    gid = 10001
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-efs-memos-ap"
  }
}
