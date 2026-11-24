# Operational Incident Response Runbook

## 1. Purpose

This runbook describes how to respond to common production incidents affecting the Sessions API.

The objective is to restore service safely, minimise downtime and protect application data.

## 2. Scenario 1: Deployment Causes Increased HTTP 5xx Errors

### Symptoms

- Increased HTTP 500, 502 or 503 responses.
- API health checks fail.
- Users report failed requests.
- Application logs show exceptions or database connection errors.

### Investigation

1. Identify when the errors started.
2. Check whether a new deployment occurred immediately before the incident.
3. Review application logs in CloudWatch.
4. Check ECS task health and load balancer target health.
5. Check database connectivity and application configuration.
6. Compare error rates before and after deployment.

### Recovery

1. If the new release is responsible, initiate rollback.
2. Restore the last known good application image.
3. Wait for ECS tasks to become healthy.
4. Verify the load balancer target health.
5. Test the API health endpoint.
6. Monitor HTTP 5xx errors to confirm recovery.

### Prevention

- Run automated tests before deployment.
- Scan container images for vulnerabilities.
- Deploy to staging before production.
- Require production approval.
- Verify application health after deployment.

## 3. Scenario 2: Sudden Increase in Traffic

### Symptoms

- Increased request count.
- Higher response times.
- High ECS CPU or memory utilisation.
- Increased HTTP errors.
- Increased database connections.

### Investigation

1. Check request count and traffic patterns.
2. Review ECS CPU and memory metrics.
3. Check application response times.
4. Review database connection utilisation.
5. Identify slow API endpoints and database queries.
6. Determine whether the increase is legitimate traffic or suspicious activity.

### Recovery and Scaling

1. Confirm that the API and database are healthy.
2. Increase ECS task capacity if the application is compute-bound.
3. Configure ECS Service Auto Scaling based on suitable metrics.
4. Review database connection limits and query performance.
5. Consider database scaling if the database is the bottleneck.
6. Reassess resource utilisation after scaling.

### Cost Considerations

Increasing ECS task count, CPU and memory increases compute costs.

Database instance upgrades and increased storage also increase costs.

Before scaling, estimate the additional monthly cost and monitor resource utilisation to avoid unnecessary spending.

## 4. Scenario 3: Database Becomes Unavailable

### Symptoms

- API requests fail.
- Database connection errors appear in application logs.
- PostgreSQL health checks fail.
- Database-dependent endpoints stop working.

### Investigation

1. Check database instance or container status.
2. Review PostgreSQL logs.
3. Check network connectivity between ECS and RDS.
4. Verify security group rules.
5. Check database credentials and Secrets Manager access.
6. Review available storage, CPU and database connections.

### Recovery

For the local Docker Compose environment:

```bash
docker compose ps
docker compose logs db
docker compose restart db
```

For AWS production:

1. Check the RDS instance status and recent events.
2. Investigate networking, credentials and resource constraints.
3. If the database cannot recover, follow the database recovery runbook.
4. Restore from an appropriate backup if required.
5. Verify data integrity.
6. Confirm that the application can connect to the recovered database.
7. Monitor the API and database after recovery.

### Data Integrity

After recovery:

- Verify important tables and records.
- Check expected record counts.
- Test representative API operations.
- Confirm that no unexpected data loss occurred.
- Document the recovery point and any missing data.

## 5. Incident Communication

For every major incident:

1. Notify the responsible team.
2. Record the incident start time.
3. Document affected services and users.
4. Record investigation and recovery actions.
5. Confirm when service is restored.
6. Perform a post-incident review.
7. Document preventive improvements.

## 6. Implementation Status

- Local Docker Compose API and database: tested successfully.
- API health endpoint: tested locally.
- ECS scaling and AWS recovery configuration: documented as the cloud deployment approach.
- CloudWatch metrics and logging: defined in Terraform.
- Production incident scenarios: documented.
- Live AWS incident