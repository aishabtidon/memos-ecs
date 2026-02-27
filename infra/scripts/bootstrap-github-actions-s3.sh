#!/usr/bin/env bash
# One-time bootstrap: attach inline policies to the GitHub Actions role so
# Terraform apply can run (state + Route53/ACM/ELB/ECR/EFS). Run with AWS CLI
# credentials that can put-role-policy (e.g. your admin user). After apply
# succeeds once, Terraform will manage the role policy; you can remove these
# inline policies later if desired.
set -e
ROLE_NAME="memos-dev-github-actions"
BUCKET="aishabtidon-terraform-state"
TABLE="terraform-locks"
REGION="eu-north-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

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

echo "Attaching terraform-services-bootstrap (Route53, ACM, ELB, ECR, EFS)..."
SERVICES_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["route53:*", "acm:*", "elasticloadbalancing:*", "elasticfilesystem:*"],
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

echo "Done. Role $ROLE_NAME has state + Terraform service permissions. Push to main or re-run the Terraform Apply workflow."
