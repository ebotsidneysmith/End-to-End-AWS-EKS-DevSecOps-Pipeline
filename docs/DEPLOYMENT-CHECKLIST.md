# Deployment checklist

## Before deployment
- [ ] Pull request reviewed and merged to `main`.
- [ ] Unit tests pass and JaCoCo report generated.
- [ ] Dependency-Check and Trivy scans reviewed.
- [ ] SonarCloud quality gate passes.
- [ ] Docker image scan passes.
- [ ] Image tagged with the Git commit SHA and pushed to ECR.
- [ ] Development cluster and namespace access verified.

## Development validation
- [ ] Deployment rollout completes.
- [ ] Pods become Ready.
- [ ] Service endpoints exist.
- [ ] Application health endpoint responds.
- [ ] QA / functional checks pass.

## Production release
- [ ] Production environment approval received.
- [ ] Exact tested image tag/digest selected.
- [ ] Rollback image is still available in ECR.
- [ ] Production rollout completes and health is verified.
- [ ] Monitoring and application logs checked.

## Rollback
1. Identify the previous healthy ReplicaSet/image.
2. Run `kubectl rollout undo deployment/store-api -n prod`, or deploy the known-good image tag.
3. Wait for `kubectl rollout status`.
4. Verify readiness, ALB target health (if configured), application logs, and user-facing behavior.
5. Record the incident and follow-up actions.
