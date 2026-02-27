# Bootstrap GitHub Actions role (one-time)

The **Terraform Apply** workflow applies the IAM module first (`-target=module.iam`) so the role’s policy is updated before plan/apply. The very first time, the role doesn’t have those permissions yet, so you need a one-time bootstrap.

**Run once** (with AWS CLI credentials that can attach IAM policies):

```bash
cd infra/scripts
./bootstrap-github-actions-s3.sh
```

On Windows (PowerShell): `bash infra/scripts/bootstrap-github-actions-s3.sh`  
Or from repo root: `bash infra/scripts/bootstrap-github-actions-s3.sh`

This attaches three inline policies to `memos-dev-github-actions`:

1. **terraform-state-access** – S3 state bucket + DynamoDB lock table  
2. **terraform-services-bootstrap** – Route53, ACM, ELB, ECR, EFS, Logs, ECS  
3. **terraform-iam-self-update** – IAM read/put/delete on the role and OIDC provider (so the workflow can run `apply -target=module.iam`)

After that, push to `main`. The workflow will apply the IAM module (updating the role’s main policy), then plan and apply the rest. You can remove the three inline policies later if you want everything in the Terraform-managed policy only.
