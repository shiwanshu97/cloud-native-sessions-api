# Database Backup and Recovery Runbook

## 1. Purpose

This runbook describes how to protect PostgreSQL data, recover from database failures and verify data integrity after restoration.

The Sessions API uses PostgreSQL as its persistent database.

## 2. Backup Strategy

### AWS Production Design

The Terraform configuration defines the following RDS backup settings:

- Automated backups enabled.
- Backup retention period of 7 days.
- Storage encryption enabled.
- Production database deletion protection enabled.
- Production database configured for Multi-AZ deployment.

Automated backups allow recovery to a selected point within the available backup retention period.

### Local Development

The Docker Compose configuration uses a named Docker volume called `postgres_data` to persist PostgreSQL data across container restarts.

Check the volume:

```bash
docker volume ls
```

Important: A Docker volume provides persistence, not an independent backup. Local database backups should also be exported and stored securely.

## 3. Local PostgreSQL Backup

Create a database backup using:

```bash
docker exec sessions-db-container pg_dump -U sessions_user -d sessions_db -F c -f /tmp/sessions_backup.dump
```

Copy the backup to the project machine:

```bash
docker cp sessions-db-container:/tmp/sessions_backup.dump ./sessions_backup.dump
```

The backup file should be stored securely and should not be committed to GitHub.

## 4. Local PostgreSQL Restore

Before restoring, make sure the database container is running.

Copy the backup into the container:

```bash
docker cp ./sessions_backup.dump sessions-db-container:/tmp/sessions_backup.dump
```

Restore the backup:

```bash
docker exec sessions-db-container pg_restore -U sessions_user -d sessions_db --clean --if-exists /tmp/sessions_backup.dump
```

A restore should be performed carefully because it can replace existing database objects and data. For an actual recovery exercise, prefer restoring into a separate test database first.

## 5. AWS RDS Recovery Procedure

If the production database becomes unavailable:

1. Identify the affected database and environment.
2. Check RDS instance status and AWS health events.
3. Review CloudWatch database metrics and application logs.
4. Determine whether the problem is temporary, network-related or caused by database failure.
5. If recovery is required, identify the latest suitable automated backup or recovery point.
6. Restore the database to a new RDS instance using the approved recovery procedure.
7. Verify the restored database before directing application traffic to it.
8. Update the application database endpoint or configuration if necessary.
9. Restart or redeploy application tasks.
10. Verify API health and database connectivity.
11. Notify stakeholders and document the incident.

Restoring to a new database instance helps preserve the original database for investigation.

## 6. Data Integrity Verification

After recovery:

- Confirm that PostgreSQL is accepting connections.
- Check that expected tables exist.
- Verify important records and their expected counts.
- Check representative session records.
- Test API read and write operations.
- Check for missing or inconsistent data.
- Review application logs for database errors.

Example database connection check:

```bash
docker exec sessions-db-container pg_isready -U sessions_user -d sessions_db
```

## 7. Recovery Objectives

The proposed recovery objectives are:

| Objective | Target |
|---|---|
| Recovery Point Objective (RPO) | Up to 24 hours |
| Recovery Time Objective (RTO) | Within 4 hours |

These are proposed operational targets, not measured results or guaranteed AWS recovery times. Actual recovery depends on backup availability, database size and restoration performance.

## 8. Implementation Status

- PostgreSQL local container: tested with Docker Compose.
- Persistent Docker volume: configured.
- Local backup and restore commands: documented.
- AWS RDS automated backups: defined in Terraform with 7-day retention.
- Production deletion protection: configured in Terraform.
- Live AWS backup restoration: not performed because AWS infrastructure has not been deployed.
- Recovery objectives: proposed and documented