# Memos on AWS ECS Fargate

A production-style deployment of [Memos](https://github.com/usememos/memos) on AWS ECS Fargate, with infrastructure defined in Terraform and deployment automated via GitHub Actions. The setup uses a multi-AZ VPC, HTTPS (ACM), an application load balancer, Fargate tasks, EFS for persistent data, and CI/CD for image build and infrastructure updates.

## Table of Contents

- [Requirements](#requirements)
- [Architecture Diagram](#architecture-diagram)
- [Features](#features)
- [Folder Structure](#folder-structure)
- [Run Locally](#run-locally)
- [Deploying to AWS](#deploying-to-aws)
- [Reproducing the Setup](#reproducing-the-setup)
- [Deployment Visuals](#deployment-visuals)

## Requirements

Before running or deploying, ensure you have:

| Requirement | Purpose |
|-------------|---------|
| **Docker** | Build and run the Memos image locally and in CI |
| **Terraform** 1.6 or later | Provision and manage AWS infrastructure |
| **AWS CLI** | Configure credentials; optional for local deploy and debugging |
| **Git** | Clone the repo and push to trigger workflows |
| **GitHub account** | Host the repo and run GitHub Actions |
| **AWS account** | Run ECS, ECR, ALB, EFS, Route 53, ACM, S3, DynamoDB |

For CI/CD you will also need:

- An **S3 bucket** and **DynamoDB table** for Terraform state (create these before the first apply).
- A **Route 53 hosted zone** for your domain so ACM can validate the certificate (DNS validation).
- **GitHub Actions secrets**: `AWS_ROLE_ARN` for OIDC (apply + Docker build); for destroy only, `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

## Architecture Diagram

- **Draw.io:** Open `docs/architecture-infra.drawio` in [draw.io](https://app.diagrams.net/) or the Draw.io extension in VS Code.
- **Rendered diagram:** See `docs/images/memos.drawio.png` (export from draw.io).
- **Mermaid:** Use `docs/architecture-infra.mmd` in Mermaid Live Editor or any Mermaid-capable tool.

User traffic: **User → Route 53 → Internet Gateway → ALB (HTTPS) → ECS Fargate** in private subnets; **EFS** for persistent storage; **ECR** for images; **S3** and **DynamoDB** for Terraform state and locking. CI/CD: **Developer → GitHub Actions (OIDC) → Docker → ECR**, and **GitHub Actions → Terraform** (state in S3, lock in DynamoDB).

## Features

- Memos app running on ECS Fargate
- Multi-AZ (eu-north-1a, eu-north-1b) for availability
- HTTPS only via ACM-managed certificate
- Application Load Balancer in front of Fargate tasks in private subnets
- NAT gateway for outbound traffic from private subnets
- EFS for persistent data at `/var/opt/memos`
- CI/CD: Docker build and push to ECR, Terraform apply, post-deploy health check (OIDC for apply/build; access keys for destroy only)
- Modular Terraform under `infra/modules/` (acm, alb, ecr, ecs, efs, iam, route53, sg, vpc)
- Route 53 for DNS; Terraform state in S3 with DynamoDB locking

## Folder Structure

```
.
├── .github/
│   └── workflows/
│       ├── docker-build.yml      
│       ├── tf-apply.yml         
│       ├── tf-destroy.yml        
│       └── post-deploy-check.yml 
│
├── app/
│   └── memos/                    
│
├── docs/
│   └── images/                  
│
├── infra/
│   ├── modules/
│   │   ├── acm
│   │   ├── alb
│   │   ├── ecr
│   │   ├── ecs
│   │   ├── efs
│   │   ├── iam
│   │   ├── route53
│   │   ├── sg
│   │   └── vpc
│   │
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
├── Dockerfile
├── .dockerignore
└── README.md
```

## Run Locally

From the repo root (same Dockerfile as CI):

```bash
docker build -t memos-local .
docker run -p 5230:5230 memos-local
```

Then open **http://localhost:5230** in your browser.

## Deploying to AWS

### 1. Configure Terraform

Edit **infra/terraform.tfvars** (region, domain, subdomain, GitHub org/repo and branch). Ensure the S3 bucket and DynamoDB table for state exist and match **infra/backend.tf**.

### 2. Apply infrastructure (first time or from your machine)

```bash
cd infra
terraform init -input=false
terraform plan -var="image_tag=local" -out=tfplan
terraform apply tfplan
```

### 3. GitHub Actions

- **Secrets** (Settings → Secrets and variables → Actions):
  - **AWS_ROLE_ARN** — OIDC role ARN for the Apply and Docker Build workflows.
  - For **Terraform Destroy** only: **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY**.

- **On push to main:** Docker Build (build and push to ECR), Terraform Apply, Post-Deploy Check.
- **Terraform Destroy:** Run manually (workflow_dispatch); uses the access key secrets.

### 4. Manual image build and push (optional)

```bash
aws ecr get-login-password --region eu-north-1 \
  | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com

docker build -t memos-dev .
docker tag memos-dev:latest <ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/memos-dev:latest
docker push <ACCOUNT_ID>.dkr.ecr.eu-north-1.amazonaws.com/memos-dev:latest
```

Then run Terraform apply (or let the pipeline run it) so ECS uses the new image.

## Reproducing the Setup

1. Clone the repository.
2. Create an S3 bucket and DynamoDB table for Terraform state; set **infra/backend.tf** and **infra/terraform.tfvars** accordingly.
3. Ensure a Route 53 hosted zone exists for your domain and ACM can validate the certificate (DNS).
4. Run Terraform apply once (e.g. locally) to create the OIDC provider and GitHub Actions role; add **AWS_ROLE_ARN** to GitHub secrets.
5. Push to **main** to trigger Docker build and Terraform apply.
6. Wait for ECS and the load balancer to become healthy.
7. Access the app at your domain (e.g. **https://tm.aishabtidon.org**).

## Deployment Visuals

Screenshots and diagram exports are under **docs/images/** (uploaded to the repo for reference):

| Asset | Description |
|-------|-------------|
| **docs/images/memos.drawio.png** | Architecture diagram (export from draw.io). |
| **docs/images/deployedwithmydomain** | Memos running in the browser at the custom domain. |
| **docs/images/docker build** | Successful Docker Build workflow run. |
| **docs/images/terraform apply** | Successful Terraform Apply workflow run. |
| **docs/images/terraform destroy** | Successful Terraform Destroy workflow run. |
| **docs/images/post-deploy check** | Post-deploy health check passing. 
