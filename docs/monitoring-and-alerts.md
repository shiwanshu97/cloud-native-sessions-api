# Monitoring, Logging and Alerts

## 1. Overview

The Sessions API uses AWS CloudWatch as the proposed central monitoring and logging solution.

The local demonstration uses Docker Compose to run the API and PostgreSQL database together. AWS monitoring resources are defined in Terraform but have not been deployed.

## 2. Logging Strategy

In the AWS environment:

- ECS sends application container logs to Amazon CloudWatch Logs.
- ECS infrastructure and service events can be monitored through CloudWatch.
- Log retention is configured for 30 days.
- Logs help identify application errors, database connection failures and deployment problems.

For local troubleshooting, Docker logs can be inspected using:

```bash
docker compose logs sessions-api
docker compose logs db
```

To follow logs continuously:

```bash
docker compose logs -f sessions-api
```

## 3. Metrics to Monitor

The following metrics should be monitored:

| Metric | Purpose |
|---|---|
| HTTP 5xx errors | Detect application or server failures |
| CPU utilisation | Identify compute bottlenecks |
| Memory utilisation | Detect memory pressure |
| Request count | Understand traffic changes |
| Response time | Identify slow API responses |
| Database connections | Detect database connection exhaustion |
| ECS task health | Detect unhealthy or stopped containers |

## 4. Proposed CloudWatch Alerts

At least two alerts are required for the production environment.

### Alert 1: High HTTP 5xx Error Rate

- Metric: Application Load Balancer HTTPCode_Target_5XX_Count.
- Condition: More than 10 target 5xx responses within a 5-minute period.
- Severity: High.
- Action: Notify the operations team and investigate the application logs.
- Recovery: Roll back the latest deployment if the errors began immediately after a release.

### Alert 2: High ECS CPU Utilisation

- Metric: ECS CPUUtilization.
- Condition: CPU utilisation remains above 80% for 5 consecutive minutes.
- Severity: Medium.
- Action: Investigate request volume and application performance.
- Recovery: Increase ECS service capacity or adjust autoscaling limits after checking cost impact.

These are proposed alert thresholds. They have not been tested against a deployed AWS environment.

## 5. Application Health Checks

The API exposes a health endpoint:

```text
GET /health
```

Expected healthy response:

```json
{
  "status": "healthy"
}
```

Local health check:

```bash
curl http://localhost:8001/health
```

A successful response confirms that the local API health endpoint is responding. It does not by itself prove that every database operation is working.

## 6. Monitoring and Incident Response

When an alert occurs:

1. Identify the affected environment and service.
2. Check ECS service health and running task count.
3. Review recent application logs in CloudWatch.
4. Check CPU, memory, request count and error metrics.
5. Identify whether the issue is caused by application code, infrastructure, traffic or the database.
6. Apply the appropriate recovery procedure.
7. Verify service health after recovery.
8. Document the incident and its cause.

## 7. Local Monitoring Commands

Check running containers:

```bash
docker compose ps
```

View API logs:

```bash
docker compose logs --tail=100 sessions-api
```

View database logs:

```bash
docker compose logs --tail=100 db
```

Check API health:

```bash
curl http://localhost:8001/health
```

## 8. Implementation Status

- CloudWatch log group and 30-day retention: defined in Terraform.
- ECS Container Insights: enabled in Terraform configuration.
- Application health endpoint: tested locally.
- CloudWatch alert thresholds: documented as proposed operational alerts.
- Live CloudWatch dashboards and alarms: not deployed because AWS infrastructure has not been applied.