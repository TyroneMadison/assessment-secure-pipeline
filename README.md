# Containerized Web Service with Secure, Observable Pipeline

Automates the deployment of a containerized web service through a full pipeline: build, scan, provision, deploy, verify, rollback. Built and run locally, no live cloud account, using the Terraform Docker provider so every apply is against real running infrastructure rather than a plan file with nothing behind it.

## Stack

| Layer | Tool |
|---|---|
| Container | Docker |
| Registry | Local Docker registry, standing in for ECR |
| IaC | Terraform, docker provider |
| Pipeline | PowerShell script, staged like a CI/CD workflow |
| Scanning | Docker Scout |
| Language | Python, standard library only |

## Architecture
## Requirements mapping

| # | Requirement | Where |
|---|---|---|
| 1 | Build, tag, push to a registry | `app/Dockerfile`, pushed to a local registry container |
| 2 | IaC provisions compute and networking | `main.tf`, dedicated bridge network plus container resource |
| 3 | CI/CD pipeline, build/test/deploy on change | `pipeline.ps1`, seven staged steps |
| 4 | Two security controls | Secret via mounted file (not env), Docker Scout blocking gate |
| 5 | Observability | `/health` endpoint, structured JSON logs, container and infra level healthchecks, rollback via retag |

## Quick start

```powershell
docker run -d -p 5000:5000 --name registry registry:2
terraform init
powershell -ExecutionPolicy Bypass -File .\pipeline.ps1
curl.exe http://localhost:8082/health
```

## Security controls

**Secrets management.** `app_secret` is a Terraform variable marked sensitive, sourced from `terraform.tfvars`, which is gitignored and never committed. Delivered to the container as a mounted file at `/run/secrets/app_secret` rather than an environment variable, so it does not surface in `docker inspect` or `/proc/1/environ`.

**Vulnerability scanning.** Docker Scout runs as a blocking stage before push, gating on critical and high severity findings. This is not simulated, it caught a real critical CVE in the base image during development and halted the pipeline until the image was patched.

## Observability

- Application level: dedicated `/health` route returning JSON
- Container level: Dockerfile `HEALTHCHECK`, 10 second interval, 3 retries
- Infrastructure level: the same healthcheck codified in the Terraform container resource
- Structured JSON log line emitted to stdout on every request
- Rollback: retag the previous known good image, redeploy through the pipeline

## Known findings, not yet fixed

- Rollback currently runs outside Terraform, causing state drift after it fires. Should route through `terraform apply` instead.
- Deploys are tracked by image tag, not digest. Pushing a new image under the same tag does not register as a Terraform diff. Fix is immutable tags or a digest reference.
- State is local, no remote backend or locking. Would break with a second engineer.
- Local registry has no auth and no TLS.

## With a live AWS account

ECS on Fargate behind an ALB, image in ECR, Scout or Trivy gating a GitHub Actions workflow, secret pulled from Secrets Manager at runtime through a scoped IAM role limited to GetSecretValue on the specific ARN, Terraform state in S3 with DynamoDB locking.
