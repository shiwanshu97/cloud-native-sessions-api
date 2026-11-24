# Deployment and Rollback Runbook

## 1. Purpose

This runbook explains how to deploy a new Sessions API version, verify its health, and recover if a deployment causes problems.

The deployment process is designed around GitHub Actions, Amazon ECR and Amazon ECS.

AWS deployment has not been executed for this assessment. The following steps document the intended cloud procedure.

## 2. Deployment Process

1. Developer pushes code to the GitHub repository.
2. GitHub Actions starts the CI/CD workflow.
3. Automated tests execute.
4. Docker image is built.
5. Trivy scans the image for known vulnerabilities.
6. If all checks pass and AWS deployment is enabled, the image is pushed to Amazon ECR.
7. The staging ECS service is updated with the new image.
8. The staging health check verifies the deployment.
9. Production deployment proceeds only after the required approval.

Each image is tagged with the Git commit SHA so that releases can be identified and restored.

## 3. Pre-deployment Checklist

- Confirm that automated tests pass.
- Confirm that the Docker build succeeds.
- Confirm that the security scan passes.
- Verify that the required environment configuration is available.
- Confirm that the previous image version is available for rollback.
- Review the release changes before production approval.

## 4. Post-deployment Verification

After deploying a new version:

1. Check ECS service health.
2. Confirm that the expected number of tasks are running.
3. Check the load balancer target health.
4. Test the API health endpoint.
5. Review application logs.
6. Check for increased HTTP 5xx errors.
7. Confirm that the application can communicate with PostgreSQL.

## 5. Rollback Conditions

Rollback should be considered when:

- HTTP 5xx errors increase significantly.
- The application health check fails.
- ECS tasks repeatedly stop or restart.
- Database connectivity fails after deployment.
- Response times become significantly worse.
- A serious security or functional issue is discovered.

## 6. Rollback Procedure

1. Identify the last known good image tag.
2. Open the GitHub Actions deployment logs and identify the failed release.
3. Update the ECS service to use the previous image.
4. Wait for ECS to replace the unhealthy tasks.
5. Verify that the expected tasks are running.
6. Check load balancer target health.
7. Test the API health endpoint.
8. Review logs and error metrics.
9. Notify the team that rollback has completed.
10. Record the incident and investigate the cause.

The previous image should be retained in ECR according to the organisation's image-retention policy.

## 7. Local Recovery Demonstration

For the local Docker Compose environment, the application can be restarted using:

```bash
docker compose restart sessions-api
```

To rebuild and restart the local services:

```bash
docker compose up --build -d
```

Check service status:

```bash
docker compose ps
```

Check application logs:

```bash
docker compose logs --tail=100 sessions-api
```

Test the API:

```bash
curl http://localhost:8001/health
```

## 8. Database Safety During Rollback

Application rollback does not automatically reverse database schema changes or restore deleted data.

Database migrations must be designed carefully to remain compatible with the previous application version whenever possible.

Before a risky database migration, take a backup and prepare a separate database recovery procedure.

## 9. Recovery Verification

A rollback is considered successful when:

- ECS tasks are healthy.
- Load balancer targets are healthy.
- The API health endpoint responds successfully.
- Database connectivity works.
- HTTP 5xx errors return to normal levels.
- Application logs show no continuing critical failures.

## 10. Implementation Status

- GitHub Actions deployment workflow: configured.
- Image tagging using Git commit SHA: configured.
- Staging and production deployment stages: configured.
- Production approval: configured.
- Post-deployment verification and rollback logic: included in the workflow.
- Live ECS deployment and rollback: not executed because AWS resources have not been created.