# Incident Response Runbook

## Severity Levels

| Level | Description | Response Time |
|-------|-------------|---------------|
| SEV-1 | Production down, all users affected | Immediate |
| SEV-2 | Degraded service, partial outage | < 15 minutes |
| SEV-3 | Non-critical issue, workaround exists | < 1 hour |

## Detection

Incidents are detected through:

1. **Automated monitoring** — `monitor.sh` logs to `health.log` and writes to `alert.log` after 3 consecutive failures
2. **CI/CD pipeline failures** — GitHub Actions alerts on failed builds or security scans
3. **Health check failures during deployment** — `deploy.sh` / `deploy-docker.sh` abort and trigger rollback

## Response Procedure

### Step 1: Assess

```bash
# Check active environment
cat ~/local-production/active_env.txt

# Check health manually
curl http://localhost:3001/health
curl http://localhost:3002/health

# Review recent logs
tail -20 health.log
tail -20 alert.log
```

### Step 2: Rollback (if deployment-related)

**PM2 mode:**
```bash
npm run rollback
```

**Docker mode:**
```bash
npm run deploy:docker   # if first deploy
npm run rollback:docker # revert to previous container
```

### Step 3: Verify Recovery

```bash
npm run post-deploy
# or specify port:
bash scripts/post-deploy-check.sh 3001
```

### Step 4: Document

Record in this file or a separate incident log:

- Timestamp of detection
- Root cause (if known)
- Actions taken
- Time to recovery
- Follow-up items

## Example Incident Log Entry

```
Date: 2026-06-30
Severity: SEV-2
Summary: Health check failed after deploy to blue environment
Detection: deploy.sh health check + monitor.sh alert
Action: Automatic rollback to green via deploy.sh failure handler
Recovery time: 45 seconds
Root cause: Missing dependency in production install
Follow-up: Added npm ci --omit=dev to deploy script
```

## Escalation

1. On-call developer (you)
2. Course instructor / team lead (for academic context)
3. Post-mortem within 48 hours for SEV-1/SEV-2 incidents

## Prevention Checklist

- [ ] All changes pass CI (lint, test, security scans)
- [ ] Post-deploy checks run after every deployment
- [ ] Secrets stored in `.env` (never committed — verified by Gitleaks in CI)
- [ ] Docker images scanned with Trivy before merge to main
