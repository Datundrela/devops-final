# Architecture

## Overview

This project merges two prior assignments into a single production-ready DevOps solution:

- **Midterm**: Local blue-green deployment (PM2), IaC scripts, monitoring, rollback
- **Pipeline**: CI quality gate, automated testing, deployment verification

## Components

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions CI/CD                     │
│  lint → test → npm audit → gitleaks → hadolint → trivy      │
└──────────────────────────┬──────────────────────────────────┘
                           │
          ┌────────────────┴────────────────┐
          ▼                                 ▼
   PM2 Blue-Green                    Docker Blue-Green
   (ports 3001/3002)                 (nginx :8080 router)
          │                                 │
          └────────────┬────────────────────┘
                       ▼
              Express App (app.js)
              /health  /metrics  /  /user/:id  /submit
                       │
                       ▼
              monitor.sh → health.log / alert.log
```

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code; triggers full CI + deploy verification |
| `dev` | Integration branch; triggers CI on push/PR |
| `feature/*` | Feature work; merge to `dev` via PR |

## Deployment Modes

1. **Local (PM2)** — `npm run setup` then `npm run deploy`
2. **Docker (single)** — `npm run setup:docker` (runs on port 3000)
3. **Docker (blue-green)** — `bash scripts/deploy-docker.sh` (nginx on 8080)
