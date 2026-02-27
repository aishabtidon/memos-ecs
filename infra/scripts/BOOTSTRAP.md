# Bootstrap GitHub Actions role (one-time)

If the **Terraform Apply** workflow fails with `AccessDenied` on Route53, ACM, ELB, ECR, or EFS, the GitHub Actions role has not yet been updated with those permissions. Terraform can't update the role until apply succeeds, so you need a one-time bootstrap.

**Run once** (with AWS CLI configured with credentials that can attach IAM policies):

```bash
cd infra/scripts
./bootstrap-github-actions-s3.sh
```

On Windows (PowerShell):

```powershell
cd infra\scripts
bash bootstrap-github-actions-s3.sh
```

Or with WSL/Git Bash from repo root:

```bash
bash infra/scripts/bootstrap-github-actions-s3.sh
```

This attaches two inline policies to `memos-dev-github-actions`:

1. **terraform-state-access** – S3 state bucket + DynamoDB lock table  
2. **terraform-services-bootstrap** – Route53, ACM, ELB, ECR, EFS (so plan/apply can read and manage those resources)

After that, push to `main` or re-run the **Terraform Apply** workflow; it should succeed. Terraform will then manage the role's main policy; you can remove the two inline policies later if you want everything in one managed policy.
