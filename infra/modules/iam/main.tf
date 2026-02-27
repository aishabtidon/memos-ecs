# ECS task execution role
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-execution"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



# GitHub OIDC 
data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.github_org_repo != "" ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-oidc"
    Environment = var.environment
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.github_org_repo != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-github-actions"

  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github[0].arn }
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_org_repo}:ref:refs/heads/${var.github_branch}" }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions"
    Environment = var.environment
  }
}

# GitHub Actions role policy: state + services (ECS, ECR, Route53, ACM, ELB, EFS, Logs, EC2, IAM).
# The tf-apply workflow runs "terraform apply -target=module.iam" first so this policy is applied before plan/apply.
locals {
  execution_role_arn          = aws_iam_role.ecs_task_execution.arn
  github_actions_ecr_resources = [var.ecr_repository_arn]
  github_actions_ecs_resources = [
    "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-${var.environment}-cluster",
    "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-${var.environment}-cluster/*",
    "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-${var.environment}:*"
  ]
  

  github_actions_core_statements_no_iam = [
    {
      Effect   = "Allow"
      Action   = ["ecr:GetAuthorizationToken"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["ecr:DescribeRepositories", "ecr:DescribeImages", "ecr:ListImages", "ecr:CreateRepository", "ecr:ListTagsForResource", "ecr:GetLifecyclePolicy", "ecr:PutLifecyclePolicy"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"]
      Resource = local.github_actions_ecr_resources
    },
    {
      Effect   = "Allow"
      Action   = ["ecs:CreateService", "ecs:DeleteService", "ecs:UpdateService", "ecs:RegisterTaskDefinition", "ecs:DeregisterTaskDefinition", "ecs:RunTask", "ecs:StopTask", "ecs:TagResource"]
      Resource = local.github_actions_ecs_resources
    },
    {
      Effect   = "Allow"
      Action   = ["ecs:*"]
      Resource = "*"
    },
    {
      Effect   = "Allow"
      Action   = ["ec2:*", "elasticloadbalancing:*", "route53:*", "acm:*", "logs:*", "elasticfilesystem:*"]
      Resource = "*"
    },
    {
      Effect    = "Allow"
      Action    = ["iam:PassRole"]
      Resource  = [local.execution_role_arn]
      Condition = { StringEquals = { "iam:PassedToService" = "ecs-tasks.amazonaws.com" } }
    },
    {
      Effect   = "Allow"
      Action   = ["iam:Get*", "iam:List*", "iam:Create*", "iam:Delete*", "iam:Update*", "iam:Put*", "iam:Attach*", "iam:Detach*", "iam:Tag*", "iam:Untag*"]
      Resource = "*"
    }
  ]


  github_actions_iam_statement = var.github_org_repo != "" ? [{
    Effect   = "Allow"
    Action   = ["iam:GetRole", "iam:GetOpenIDConnectProvider", "iam:ListRolePolicies", "iam:GetRolePolicy", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:DeleteRole"]
    Resource = [local.execution_role_arn, aws_iam_role.github_actions[0].arn, aws_iam_openid_connect_provider.github[0].arn]
  }] : []

  github_actions_core_statements = concat(local.github_actions_core_statements_no_iam, local.github_actions_iam_statement)

  github_actions_policy_statements = concat(
    var.github_org_repo != "" && var.terraform_state_bucket_name != "" ? [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:HeadObject", "s3:ListBucket"]
      Resource = ["arn:aws:s3:::${var.terraform_state_bucket_name}", "arn:aws:s3:::${var.terraform_state_bucket_name}/*"]
    }] : [],
    var.github_org_repo != "" && var.terraform_state_dynamodb_table_name != "" ? [{
      Effect   = "Allow"
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:ConditionCheckItem", "dynamodb:BatchGetItem"]
      Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.terraform_state_dynamodb_table_name}"
    }] : [],
    [for s in local.github_actions_core_statements : s if var.github_org_repo != ""]
  )
}

resource "aws_iam_role_policy" "github_actions" {
  count = var.github_org_repo != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-github-actions"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.github_actions_policy_statements
  })
}
