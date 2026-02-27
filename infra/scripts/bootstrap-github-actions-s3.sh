#!/usr/bin/env bash
set -e
ROLE_NAME="memos-dev-github-actions"
BUCKET="aishabtidon-terraform-state"
TABLE="terraform-locks"
REGION="eu-north-1"
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
POLICY=$(cat <<EOF
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
aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name terraform-state-access --policy-document "$POLICY"
echo "Done. Role $ROLE_NAME can now access state bucket and DynamoDB. Re-run the pipeline."
