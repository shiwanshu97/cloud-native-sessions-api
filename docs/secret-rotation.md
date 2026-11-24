# Secret Exposure and Rotation Runbook

## 1. Purpose

This runbook describes how to respond if a database password, API token, AWS credential or other deployment secret is accidentally exposed in a Git repository.

The main objectives are to contain the exposure, invalidate the compromised credential, issue a replacement and verify that services are secure.

## 2. Immediate Response

If a secret is exposed:

1. Treat the secret as compromised immediately.
2. Notify the responsible team or security owner.
3. Identify which credential was exposed and which systems use it.
4. Restrict access to the affected repository if necessary.
5. Revoke or disable the exposed credential as quickly as possible.
6. Review recent authentication activity for suspicious access.

Deleting the secret from the latest commit is not sufficient because it may remain in Git history, forks, logs or caches.

## 3. Rotate the Compromised Secret

For an AWS database password stored in Secrets Manager:

1. Access AWS Secrets Manager using an authorised account.
2. Identify the affected secret.
3. Generate a new strong password.
4. Update the database password using the approved database administration process.
5. Store the new credential in AWS Secrets Manager.
6. Confirm that the ECS task execution role has permission to retrieve the required secret.
7. Restart or redeploy the application tasks so they receive the updated credential.
8. Verify that the API can connect to the database.
9. Confirm that the old credential no longer works.

For an exposed AWS access key, deactivate and delete the compromised key and use the configured GitHub Actions OIDC authentication rather than long-lived access keys.

## 4. Remove the Secret from the Repository

After containing the incident:

1. Remove the secret from tracked source files.
2. Replace hardcoded credentials with environment variables or a secrets service.
3. Review Git history and remove exposed secret content where appropriate.
4. Coordinate history rewriting with repository collaborators.
5. Review GitHub Actions logs and repository settings for additional exposure.
6. Check for accidental copies in documentation, screenshots and build artifacts.

History cleanup does not replace credential rotation.

## 5. Prevention

The following security practices reduce the risk of future exposure:

- Store cloud database credentials in AWS Secrets Manager.
- Do not commit passwords, tokens or private keys.
- Use GitHub repository secrets or OIDC for CI/CD authentication.
- Apply least-privilege IAM permissions.
- Restrict repository access to authorised contributors.
- Review changes before merging.
- Use automated secret scanning where available.
- Rotate credentials periodically and after suspected exposure.

## 6. Verification

After rotation:

- Confirm that the new credential works.
- Confirm that the old credential is invalid.
- Verify successful application-to-database connectivity.
- Review authentication logs for suspicious activity.
- Confirm that no active repository files contain the exposed secret.
- Record the incident, actions taken and lessons learned.

## 7. Implementation Status

- AWS Secrets Manager integration: defined in Terraform.
- ECS secret retrieval permissions: defined in Terraform.
- GitHub Actions OIDC authentication: intended deployment design; AWS role setup remains pending.
- Secret exposure and rotation procedure: documented.
- Live secret rotation exercise: not performed because AWS infrastructure has not been deployed.