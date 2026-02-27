# Create repo, push to GitHub, and run CI/CD

Follow these steps in order. Skip any step you’ve already done.

---

## 1. Add a root `.gitignore`

You need a **file** named `.gitignore` in the repo root (not a folder). If you have a **folder** named `.gitignore`, remove it first, then create a **file** named `.gitignore` with the content below.

**Remove folder (if it exists) and create the file (PowerShell):**

```powershell
cd c:\Users\aisha\memos-app-ecs
# If .gitignore is a folder, remove it
Remove-Item -Recurse -Force .gitignore -ErrorAction SilentlyContinue
# Create .gitignore as a file with the content below (copy from "Copy this into .gitignore" below)
```

**Copy this into `.gitignore` (root of repo):**

```
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Keep .terraform.lock.hcl (commit it for consistent provider versions)

# Local env / secrets (do not commit)
.env
.env.*
!.env.example

# OS
.DS_Store
Thumbs.db

# IDE / editor
.idea/
.vscode/
*.swp
*.swo
*~

# Logs
*.log

# Optional: if you use local tfvars with secrets, uncomment:
# infra/*.auto.tfvars
# infra/secrets.auto.tfvars
```

**What to ignore vs keep:**

| Do **not** commit (add to .gitignore) | Do **commit** |
|----------------------------------------|---------------|
| `.terraform/` (plugins, local cache)   | `.terraform.lock.hcl` (locks provider versions) |
| `*.tfstate`, `*.tfstate.*` (state; yours is in S3) | All `.tf` and `.tfvars` (unless tfvars has secrets) |
| `*.tfplan` (saved plans can be sensitive) | |
| `.env`, `.env.*` (secrets)             | |
| `.DS_Store`, `.idea/`, `.vscode/`, `*.log` | |

If you keep secrets in extra tfvars (e.g. `secrets.auto.tfvars`), add that file to `.gitignore` and don’t commit it.

---

## 2. Create the GitHub repo (**memo-ecs**)

Your Terraform is set to trust the repo **aishabtidon/memo-ecs**. Create that repo on GitHub:

1. Log in to [GitHub](https://github.com).
2. Click **+** (top right) → **New repository** (or go to **Repositories** → **New**).
3. **Repository name:** `memo-ecs` (must match the repo part of `github_org_repo` in `infra/terraform.tfvars`).
4. **Description:** optional (e.g. "Memos on ECS").
5. **Visibility:** Private or Public.
6. **Do not** check "Add a README file", ".gitignore", or "license" — you already have code.
7. Click **Create repository**.

GitHub will show you a page with setup commands; you’ll use the **push an existing repository** section in the next step.

---

## 3. Push this repo to GitHub

In PowerShell (or Git Bash) from the **repo root**:

```powershell
cd c:\Users\aisha\memos-app-ecs

# If this folder is not a git repo yet
git init

# Add everything (respects .gitignore)
git add .

# First commit
git commit -m "Initial commit: Memos on ECS, Terraform, CI/CD workflow"

# Rename branch to main if needed
git branch -M main

# Add GitHub as remote — repo name must be memo-ecs (matches terraform.tfvars)
git remote add origin https://github.com/aishabtidon/memo-ecs.git

# Push (will ask for GitHub auth if not configured)
git push -u origin main
```

If you already have a git repo (e.g. from a different remote), set the remote to **memo-ecs** and push:

```powershell
git remote remove origin
git remote add origin https://github.com/aishabtidon/memo-ecs.git
git branch -M main
git push -u origin main
```

Replace **aishabtidon** with your GitHub username if different.

---

## 4. Add the GitHub Actions secret (for CI/CD)

1. On GitHub, open **memos-app-ecs** → **Settings** → **Secrets and variables** → **Actions**.
2. **New repository secret**.
3. **Name:** `AWS_ROLE_ARN`
4. **Value:** the role ARN from Terraform, e.g.  
   `arn:aws:iam::113817973548:role/memos-dev-github-actions`  
   (get it with: `cd infra && terraform output -raw github_actions_role_arn`)
5. Save.

Without this secret, the “Configure AWS credentials” step in the workflow will fail.

---

## 5. Run CI/CD

- **Automatic:** Push to `main` (e.g. `git push origin main`) runs the workflow **Build, Deploy, and Verify** (Build & Push → Terraform Deploy → Post-Deploy Check).
- **Manual:** **Actions** → **Build, Deploy, and Verify** → **Run workflow** → **Run workflow**.

After a successful run:

1. **Actions** tab shows all three jobs green.
2. App is at `https://tm.<your-domain>/health` (and your app URL).
3. Take a screenshot of the successful run for your deliverables.

---

## Quick checklist

| Step | Action |
|------|--------|
| 1 | Root `.gitignore` in place; `.terraform.lock.hcl` is **committed**; state/tfplan/tfvars-secrets **ignored** |
| 2 | GitHub repo `memos-app-ecs` created (no README/.gitignore) |
| 3 | `git init` (if new), `git add .`, `git commit`, `git remote add origin`, `git push -u origin main` |
| 4 | Repo secret `AWS_ROLE_ARN` = `terraform output -raw github_actions_role_arn` |
| 5 | Push to `main` or “Run workflow” → confirm all jobs pass and app is healthy |

---

## Excluding “instruction” or study docs from the push

If you don’t want to push the `study/` folder (or certain docs), either:

- **Remove from this repo before pushing:** delete or move `study/` (or specific files) and commit, then push; or  
- **Ignore them:** add to root `.gitignore`, e.g. `study/` or `docs/PUSH_AND_CICD.md`, then `git add .` and commit. Ignored files won’t be in the repo.

If you ignore `study/`, the rest of the repo (infra, app, `.github/workflows`, root Dockerfile, etc.) will still push and CI/CD will work.
