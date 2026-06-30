# Service Level Objectives (SLO)

## Availability

| Metric | Target | Measurement |
|--------|--------|-------------|
| Uptime | 99.5% monthly | `/health` returns HTTP 200 |
| Health check interval | Every 5 seconds | `monitor.sh` |
| Recovery time (RTO) | < 2 minutes | Rollback script execution |

## Latency

| Endpoint | Target (p95) |
|----------|--------------|
| `GET /health` | < 100 ms |
| `GET /` | < 200 ms |
| `POST /submit` | < 300 ms |

## Deployment

| Metric | Target |
|--------|--------|
| Deployment success rate | > 95% |
| Failed deploy auto-rollback | 100% |
| Zero-downtime switch | Required (blue-green) |

## Error Budget

If availability drops below 99.5% in a rolling 30-day window:

1. Freeze non-critical deployments
2. Prioritize reliability fixes
3. Review incident response log in `docs/INCIDENT_RESPONSE.md`

## Monitoring

- **Logs**: `health.log` (continuous health checks)
- **Alerts**: `alert.log` (triggered after 3 consecutive failures)
- **Metrics**: `GET /metrics` endpoint exposes uptime and memory usage
