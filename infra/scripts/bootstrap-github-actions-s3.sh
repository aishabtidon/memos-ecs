#!/usr/bin/env bash
# One-time bootstrap: attach inline policies so the GitHub Actions role can
# run Terraform (state + services + IAM self-update). Run with AWS CLI
# credentials that can put-role-policy. After that, the workflow applies the
# IAM module first, so Terraform manages the full role policy.
set -e
ROLE_NAME="memos-dev-github-actions"
BUCKET="aishabtidon-terraform-state"
TABLE="terraform-locks"
REGION="eu-north-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/${ROLE_NAME}"
OIDC_ARN="arn:aws:iam::${ACCOUNT}:oidc-provider/token.actions.githubusercontent.com"
EXECUTION_ROLE_ARN="arn:aws:iam::${ACCOUNT}:role/memos-dev-ecs-execution"

echo "Attaching terraform-state-access..."
STATE_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:HeadObject"],
      "Resource": ["arn:aws:s3:::${BUCKET}", "arn:aws:s3:::${BUCKET}/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:ConditionCheckItem", "dynamodb:BatchGetItem"],
      "Resource": "arn:aws:dynamodb:${REGION}:${ACCOUNT}:table/${TABLE}"
    }
  ]
}
EOF
)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name terraform-state-access --policy-document "$STATE_POLICY"

echo "Attaching terraform-services-bootstrap (Route53, ACM, ELB, ECR, EFS, Logs, ECS)..."
SERVICES_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["route53:*", "acm:*", "elasticloadbalancing:*", "elasticfilesystem:*", "logs:*", "ecs:*"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["ecr:DescribeRepositories", "ecr:CreateRepository", "ecr:DescribeImages", "ecr:ListImages", "ecr:ListTagsForResource", "ecr:GetLifecyclePolicy", "ecr:PutLifecyclePolicy"],
      "Resource": "*"
    }
  ]
}'
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name terraform-services-bootstrap --policy-document "$SERVICES_POLICY"

echo "Attaching terraform-iam-self-update (so workflow can apply module.iam)..."
IAM_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "iam:GetRole", "iam:GetOpenIDConnectProvider", "iam:ListRolePolicies",
      "iam:GetRolePolicy", "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:DeleteRole"
    ],
    "Resource": ["${ROLE_ARN}", "${OIDC_ARN}", "${EXECUTION_ROLE_ARN}"]
  }]
}
EOF
)
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name terraform-iam-self-update --policy-document "$IAM_POLICY"

echo "Done. Role $ROLE_NAME has state + services + IAM self-update. Push to main; workflow will apply IAM then plan/apply."
