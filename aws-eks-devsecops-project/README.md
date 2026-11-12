# AWS EKS DevSecOps CI/CD Demo

A reference implementation of the uploaded architecture using **GitHub Actions, Maven, JUnit, JaCoCo, OWASP Dependency-Check, Trivy, SonarCloud, Docker, Amazon ECR, and Amazon EKS**.

The pipeline builds and tests a Spring Boot application, checks source code and dependencies, enforces a SonarCloud quality gate, builds and scans a Docker image, pushes the image to ECR, deploys it to a development EKS cluster, and promotes the **same immutable image** to production after approval.

> This is a deployable starter project, not a preconfigured AWS account. Replace the placeholders and create the AWS resources/secrets described below before running the workflow. The workflow intentionally does not create EKS clusters or expose an application publicly.

## Architecture flow

1. Developer creates work in Jira, develops locally, and pushes code to GitHub.
2. GitHub Actions starts the pipeline.
3. Maven compiles the code and runs unit tests; JaCoCo publishes coverage.
4. OWASP Dependency-Check and Trivy filesystem scans check dependencies and repository files.
5. SonarCloud analyzes code and enforces the quality gate.
6. Docker builds and tags the application image.
7. Trivy scans the image; the pipeline fails on configured HIGH/CRITICAL findings.
8. GitHub Actions authenticates to AWS using OIDC and pushes the image to Amazon ECR.
9. The image is deployed to the `dev` namespace on the development EKS cluster.
10. After validation and approval through the GitHub `production` environment, that same image tag is deployed to the production EKS cluster.

## Repository layout

```text
.
├── .github/workflows/ci-cd.yml
├── app/
│   ├── pom.xml
│   └── src/
│       ├── main/java/com/example/store/StoreApplication.java
│       ├── main/java/com/example/store/HealthController.java
│       └── test/java/com/example/store/HealthControllerTest.java
├── deploy/
│   ├── base/deployment.yaml
│   ├── base/service.yaml
│   ├── base/ingress.yaml
│   ├── dev/kustomization.yaml
│   └── prod/kustomization.yaml
├── scripts/
│   ├── local-test.sh
│   └── deploy.sh
├── Dockerfile
├── .dockerignore
├── .trivyignore
├── sonar-project.properties
└── docs/architecture.png
```

## Prerequisites

- GitHub repository with Actions enabled.
- AWS account and two existing EKS clusters (or one cluster with isolated namespaces for a lab).
- Amazon ECR repository, e.g. `store-api`.
- GitHub Actions OIDC provider and an IAM role trusted by this repository.
- SonarCloud organization/project and token.
- `kubectl`, `aws`, Docker, Java 21, and Maven for local work.

## GitHub configuration

Create these **repository variables**:

| Variable | Example / meaning |
|---|---|
| `AWS_REGION` | `us-east-2` |
| `AWS_ROLE_ARN` | IAM role ARN assumed through GitHub OIDC |
| `ECR_REPOSITORY` | `store-api` |
| `EKS_DEV_CLUSTER` | development EKS cluster name |
| `EKS_PROD_CLUSTER` | production EKS cluster name |
| `SONAR_ORGANIZATION` | SonarCloud organization key |
| `SONAR_PROJECT_KEY` | SonarCloud project key |

Create this **repository secret**:

| Secret | Meaning |
|---|---|
| `SONAR_TOKEN` | SonarCloud token |

Create a GitHub Environment named **`production`** and configure required reviewers/approval rules. The `deploy-production` job waits for this approval.

For a real project, use separate AWS roles for development and production and scope each role to only its required ECR/EKS permissions. This demo uses one role variable to keep setup compact; the workflow can be split into `AWS_ROLE_ARN_DEV` and `AWS_ROLE_ARN_PROD` if desired.

## AWS setup checklist

1. Create an ECR repository matching `ECR_REPOSITORY`.
2. Configure GitHub OIDC in IAM (`token.actions.githubusercontent.com`).
3. Restrict the IAM role trust policy to your GitHub organization/repository and branch/environment. Do not use an unrestricted subject.
4. Grant the role ECR push/pull permissions and EKS access to the intended clusters.
5. Map the IAM role into EKS access entries (or your cluster's supported access mechanism) with permissions to manage the `dev` namespace and production application resources.
6. Ensure the EKS clusters have worker nodes/Fargate profiles able to pull from ECR.
7. Configure an Ingress controller / AWS Load Balancer Controller and DNS/TLS separately if you want an externally reachable URL.

The workflow deploys to existing clusters; it does not provision VPCs, EKS, node groups, ECR, ALB, DNS, or certificates.

## SonarCloud setup

1. Create a SonarCloud project and generate a token.
2. Add `SONAR_TOKEN` as a GitHub secret.
3. Set `SONAR_ORGANIZATION` and `SONAR_PROJECT_KEY` as repository variables.
4. Ensure the project key and organization match the SonarCloud project.

The Maven command waits for the quality gate. A failed gate stops the pipeline before the image is published.

## Run locally

```bash
cd app
mvn clean verify
```

Build and run the container:

```bash
docker build -t store-api:local .
docker run --rm -p 8080:8080 store-api:local
curl http://localhost:8080/actuator/health
```

The app exposes `/actuator/health` for container and Kubernetes health checks.

## Deploy manually (optional)

Authenticate to the correct AWS account, update kubeconfig, then run:

```bash
aws eks update-kubeconfig --region us-east-2 --name YOUR_DEV_CLUSTER
kubectl apply -k deploy/dev
kubectl rollout status deployment/store-api -n dev
```

Production:

```bash
aws eks update-kubeconfig --region us-east-2 --name YOUR_PROD_CLUSTER
kubectl apply -k deploy/prod
kubectl rollout status deployment/store-api -n prod
```

## Rollback

Kubernetes keeps rollout history for the Deployment:

```bash
kubectl rollout history deployment/store-api -n prod
kubectl rollout undo deployment/store-api -n prod
kubectl rollout status deployment/store-api -n prod
```

For a deterministic rollback to a known release, set the Deployment image to the previous ECR tag and apply it. Keep old ECR images according to a retention policy; do not delete the last known-good release.

## Production safety notes

- Promote the same immutable image tag/digest that passed development validation; do not rebuild for production.
- Consider using image digests (`image@sha256:...`) for stronger immutability in a hardened pipeline.
- Set resource requests/limits, PodDisruptionBudgets, network policies, and autoscaling based on measured workload requirements.
- Configure readiness/liveness/startup probes and meaningful application health checks.
- Use Secrets Manager / External Secrets or another approved secret mechanism; do not commit secrets to Git.
- Add database migration compatibility and backup/restore plans before production releases.
- Review Trivy findings rather than blindly suppressing them. `.trivyignore` is intentionally empty.
- Use protected branches, required reviews, and GitHub environment approvals.

## Customizing the sample

This starter contains a small Spring Boot health endpoint so the pipeline can run end-to-end. Replace it with your application while retaining the health endpoint or updating the Docker and Kubernetes probes.
