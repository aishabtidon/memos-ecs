data "aws_caller_identity" "current" {}

locals {
  ecr_repository_arn = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${var.environment}"
}

# vpc module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# Security groups
module "sg" {
  source = "./modules/sg"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  container_port = var.container_port

  depends_on = [module.vpc]
}

# ACM certificate for HTTPS (destroyed before IAM so role exists for API calls)
module "acm" {
  source = "./modules/acm"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = "${var.subdomain}.${var.root_domain}"
  root_domain  = var.root_domain

  depends_on = [module.iam]
}

# Application Load Balancer (destroyed before IAM)
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.sg.alb_security_group_id
  container_port        = var.container_port
  health_check_path     = var.health_check_path
  enable_https          = true
  acm_certificate_arn   = module.acm.certificate_arn

  depends_on = [module.vpc, module.sg, module.iam]
}

# ECR repository (depends on IAM so destroy runs before IAM; role needed for ECR delete)
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  depends_on = [module.iam]
}

# IAM: ECS execution role + GitHub OIDC (destroyed last so role exists for entire destroy)
module "iam" {
  source = "./modules/iam"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  ecr_repository_arn = local.ecr_repository_arn

  github_org_repo = var.github_org_repo
  github_branch   = var.github_branch
  terraform_state_bucket_name         = var.terraform_state_bucket_name
  terraform_state_dynamodb_table_name = var.terraform_state_dynamodb_table_name
}

# EFS for persistent storage (destroyed before IAM)
module "efs" {
  source = "./modules/efs"

  project_name          = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.vpc.private_subnet_ids
  efs_security_group_id = module.sg.efs_security_group_id

  depends_on = [module.vpc, module.sg, module.iam]
}

# ECS Fargate service
module "ecs" {
  source = "./modules/ecs"

  project_name             = var.project_name
  environment              = var.environment
  aws_region               = var.aws_region
  container_name           = var.container_name
  container_port           = var.container_port
  ecr_repository_url       = module.ecr.repository_url
  image_tag                = var.image_tag
  efs_id                   = module.efs.file_system_id
  efs_access_point_id      = module.efs.access_point_id
  efs_mount_path           = "/var/opt/memos"
  task_execution_role_arn  = module.iam.ecs_task_execution_role_arn
  task_role_arn            = null
  private_subnet_ids       = module.vpc.private_subnet_ids
  ecs_security_group_id   = module.sg.ecs_security_group_id
  target_group_arn        = module.alb.target_group_arn

  depends_on = [module.alb, module.ecr, module.efs, module.iam]
}

# Route53 Module (destroyed before IAM)
module "route53" {
  source = "./modules/route53"

  project_name = var.project_name
  environment  = var.environment
  domain_name  = var.root_domain
  subdomain    = var.subdomain
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.alb_zone_id

  depends_on = [module.alb, module.iam]
}
