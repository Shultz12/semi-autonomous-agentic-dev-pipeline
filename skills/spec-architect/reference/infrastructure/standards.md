# Infrastructure Specification Standards

This document defines infrastructure specification standards to ensure reliable, scalable, and maintainable systems.

## Database Migrations

### Zero-Downtime Patterns

**PostgreSQL Safe Operations:**
- `CREATE INDEX CONCURRENTLY` - Build indexes without blocking writes
- `ADD COLUMN` with defaults - Add nullable columns first, backfill, then add constraints
- `DROP COLUMN` - Mark deprecated first, remove after verification
- Avoid `ALTER TYPE`, `ALTER COLUMN TYPE` on large tables - use shadow columns instead

**Migration Phases:**
1. **Preparation** - Create new structures (indexes, columns, tables)
2. **Dual-Write** - Write to both old and new structures
3. **Backfill** - Migrate existing data in batches
4. **Dual-Read** - Verify data consistency
5. **Switch** - Route reads to new structure
6. **Cleanup** - Remove old structures after validation period

### Batch Processing

**Data Migration Requirements:**
- Process in batches (1000-10000 rows depending on row size)
- Include progress logging every batch
- Implement resume capability (track last processed ID)
- Add rate limiting to avoid overwhelming database
- Monitor replication lag during migration

### Rollback Plans

**Every migration must include:**
- Automated rollback script tested in staging
- Rollback decision criteria (error rate threshold, latency increase)
- Data reconciliation plan if rolled back mid-migration
- Communication plan for rollback scenario

### Pre/Post Migration Checklists

**Pre-Migration:**
- [ ] Verified in staging environment with production-like data volume
- [ ] Backup completed and verified
- [ ] Rollback script tested
- [ ] Lock analysis completed (no long-running locks expected)
- [ ] Monitoring dashboards prepared
- [ ] Stakeholders notified

**Post-Migration:**
- [ ] Data consistency verified
- [ ] Performance metrics within baseline
- [ ] No error spikes in logs
- [ ] Cleanup tasks scheduled
- [ ] Documentation updated

### Lock Analysis

**Required for each migration:**
- Identify lock types (AccessExclusiveLock, ShareLock, RowExclusiveLock)
- Estimate lock duration
- Plan migration window based on lock requirements
- Use `statement_timeout` to prevent runaway queries

## Deployment

### Deployment Strategies

**Blue-Green Deployment:**
- **Use when:** Zero-downtime required, easy rollback critical
- **Process:** Deploy to idle environment, run smoke tests, switch traffic, keep old version for quick rollback
- **Requirements:** 2x infrastructure, database compatibility across versions

**Canary Deployment:**
- **Use when:** Gradual rollout needed, A/B testing required
- **Process:** Deploy to subset (5% → 25% → 50% → 100%), monitor metrics at each stage
- **Requirements:** Traffic routing capability, real-time metrics

**Rolling Deployment:**
- **Use when:** Resource-constrained, moderate risk tolerance
- **Process:** Update instances one-by-one, monitor health between updates
- **Requirements:** Minimum 3 instances, backward-compatible changes

### Health Checks

**HTTP /health Endpoint Requirements:**
```json
{
  "status": "healthy|degraded|unhealthy",
  "version": "1.2.3",
  "timestamp": "2026-01-27T10:00:00Z",
  "checks": {
    "database": "healthy",
    "redis": "healthy",
    "storage": "healthy"
  },
  "uptime": 86400
}
```

**Health Check Criteria:**
- Database connection pool has available connections
- Redis responds to PING within 100ms
- File storage accessible
- No critical background jobs failing

### Rollback Triggers

**Automatic Rollback Conditions:**
- Error rate > 5% for 2 minutes
- P95 latency > 2x baseline for 5 minutes
- Health check failures > 50% of instances
- Critical dependency unavailable

**Manual Rollback Procedures:**
1. Execute rollback command (documented per deployment type)
2. Verify old version health checks pass
3. Monitor error rates return to baseline
4. Notify stakeholders
5. Schedule post-mortem

### Deployment Gates

**Required Approvals:**
- All tests passing (unit, integration, e2e)
- Security scan passed (no high/critical vulnerabilities)
- Performance regression tests passed
- Staging environment validated
- Production deployment window approved

## CI/CD

### Pipeline Stages

**Standard Pipeline Flow:**
```
lint → test → security scan → build → deploy → smoke test → notify
```

**Stage Details:**

1. **Lint** - ESLint, Prettier, TypeScript strict checks
2. **Test** - Unit tests (>80% coverage), integration tests
3. **Security Scan** - Dependency audit, SAST (static analysis), secret detection
4. **Build** - Docker image build, tag with git commit SHA
5. **Deploy** - Deploy to environment based on branch
6. **Smoke Test** - Critical path validation (login, core workflow)
7. **Notify** - Slack/email notification with deployment status

### Quality Gates

**Must Pass to Proceed:**
- Test coverage > 80%
- No high/critical security vulnerabilities
- No ESLint errors (warnings allowed)
- Build size within limits (backend < 500MB, frontend < 5MB)
- Smoke tests 100% passing

### Automated Rollback Triggers

**CI/CD Pipeline Rollback:**
- Smoke tests fail after deployment
- Health checks don't stabilize within 5 minutes
- Error rate spike detected by monitoring
- Manual rollback flag set

## Monitoring

### Three Pillars

**1. Metrics (RED Method)**
- **Rate:** Requests per second by endpoint
- **Errors:** Error rate (4xx, 5xx) by endpoint
- **Duration:** P50, P95, P99 latency by endpoint

**Key Metrics:**
- API response time (P95 < 500ms, P99 < 1s)
- Database query time (P95 < 100ms)
- Background job processing time
- Memory usage (< 80% of limit)
- CPU usage (< 70% sustained)
- Active connections (database, Redis)

**2. Structured JSON Logs**
```json
{
  "timestamp": "2026-01-27T10:00:00Z",
  "level": "error",
  "message": "Processing failed",
  "context": {
    "userId": "123",
    "tenantId": "456",
    "resourceId": "789",
    "error": "Invalid input structure"
  },
  "trace_id": "abc-def-123"
}
```

**3. Distributed Tracing**
- Trace ID propagation across services
- Span annotations for critical operations
- Performance profiling for slow requests

### Alert Severity

**P0 - Critical (Page Immediately)**
- Service completely down
- Data loss occurring
- Security breach detected

**P1 - High (Notify Within 15 Minutes)**
- Degraded performance affecting users
- High error rates (>5%)
- Critical dependency failing

**P2 - Medium (Notify Within 1 Hour)**
- Non-critical feature broken
- Warning threshold exceeded
- Capacity planning alert

**P3 - Low (Daily Summary)**
- Minor issues
- Informational alerts
- Optimization opportunities

### Dashboard Specifications

**Required Dashboards:**
1. **Service Overview** - Overall health, request rate, error rate, latency
2. **Database** - Query performance, connection pool, slow queries
3. **Background Jobs** - Queue depth, processing time, failure rate
4. **Business Metrics** - Core operations/hour, active users, resource consumption
5. **Infrastructure** - CPU, memory, disk, network

### Alert Fatigue Prevention

**Best Practices:**
- Alert on symptoms (user impact), not causes (server metrics)
- Use dynamic thresholds based on historical patterns
- Implement alert aggregation (don't alert on every instance)
- Regular alert review and tuning (monthly)
- Clear runbook linked to each alert

## Security Hardening

### Network Security

**Requirements:**
- Private subnets for database and Redis
- Security groups restrict access to minimum required
- TLS 1.3 for all external communication
- mTLS for internal service communication (if microservices)
- Rate limiting at API gateway (100 req/min per IP)
- DDoS protection enabled

### Secrets Management

**Secret Storage:**
- Use cloud provider secret manager (AWS Secrets Manager, Azure Key Vault)
- Never commit secrets to git
- Environment-specific secrets
- Encrypted at rest and in transit

**Secret Rotation:**
- Database passwords: every 90 days
- API keys: every 180 days
- TLS certificates: auto-renewal 30 days before expiry
- Service account keys: every 90 days

**Access Control:**
- Principle of least privilege
- Role-based access to secrets
- Audit log for secret access
- Break-glass procedure for emergencies

### RBAC for Infrastructure

**Infrastructure Access Roles:**
- **Admin** - Full access, production changes
- **Developer** - Read access to production, full access to dev/staging
- **Operator** - Deployment access, read-only infrastructure changes
- **Auditor** - Read-only access, audit log access

### Compliance and Audit Logging

**Required Audit Events:**
- Authentication/authorization events
- Infrastructure changes (deployments, config changes)
- Data access (PII, financial data)
- Secret access and rotation
- Security events (failed logins, rate limit hits)

**Retention:**
- Audit logs: 1 year minimum
- Security logs: 90 days minimum
- Application logs: 30 days

## Backup & Recovery

### RPO/RTO Definitions

**Recovery Point Objective (RPO):**
- Maximum acceptable data loss
- [Project target, e.g., 1 hour]

**Recovery Time Objective (RTO):**
- Maximum acceptable downtime
- [Project target, e.g., 4 hours]

### PostgreSQL Backup Strategy

**Full Backups:**
- Daily full backup at 2 AM UTC
- Retained for 30 days
- Encrypted at rest
- Verified weekly via restore test

**WAL Archiving:**
- Continuous WAL archiving to object storage
- Enables point-in-time recovery (PITR)
- 7-day retention

**Backup Verification:**
- Weekly automated restore to test environment
- Integrity check on restored data
- Alert if restore fails

### Redis Persistence

**RDB (Snapshot):**
- Save snapshot every 15 minutes if 1+ keys changed
- Retained for 7 days

**AOF (Append-Only File):**
- AOF enabled with fsync every second
- AOF rewrite when file grows 100%

**Persistence Strategy:**
- Use both RDB and AOF for durability
- RDB for faster restarts, AOF for minimal data loss

### File Storage Versioning

**Object Storage:**
- Enable versioning on all buckets
- Retain deleted objects for 30 days
- Lifecycle policy to move old versions to cheaper storage

### Monthly Restore Drills

**Restore Drill Procedure:**
1. Schedule drill (announced, not surprise)
2. Restore database backup to test environment
3. Verify data integrity (row counts, checksums)
4. Test application against restored database
5. Measure restore time (must meet RTO)
6. Document issues and improvements
7. Update runbook

## Scaling

### Autoscaling Rules

**Horizontal Pod Autoscaling (HPA):**
- **Scale Up Trigger:** CPU > 70% for 2 minutes OR memory > 80% for 2 minutes
- **Scale Down Trigger:** CPU < 30% for 5 minutes AND memory < 40% for 5 minutes
- **Min Instances:** 2 (high availability)
- **Max Instances:** 10 (cost control)
- **Cooldown:** 3 minutes scale up, 5 minutes scale down

### Database Scaling

**Read Replicas:**
- Create read replica for read-heavy workloads
- Route read queries to replicas
- Monitor replication lag (< 1 second)
- Use connection pooling to distribute load

**Connection Pooling via PgBouncer:**
- Transaction pooling mode (default)
- Pool size: 20 connections per instance
- Max client connections: 100
- Idle timeout: 10 minutes

**Sharding Evaluation:**
- Consider when single database > 500GB
- Shard by tenant_id for multi-tenant isolation
- Use PostgreSQL foreign data wrappers or application-level sharding

### Capacity Planning

**Quarterly Review:**
- Analyze growth trends (users, data volume, request rate)
- Project capacity needs for next 6 months
- Identify bottlenecks (CPU, memory, database, storage)
- Plan infrastructure scaling or optimization

**Capacity Thresholds:**
- Storage: Alert at 70%, scale at 80%
- Database connections: Alert at 70%, scale at 80%
- CPU/Memory: Alert at 70%, scale at 80%

## Infrastructure-as-Code

### Terraform Module Structure

**Directory Structure:**
```
infrastructure/
├── modules/
│   ├── networking/
│   ├── database/
│   ├── compute/
│   └── monitoring/
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── shared/
```

**Module Best Practices:**
- Reusable modules with clear inputs/outputs
- Version modules (git tags)
- Document module usage in README
- Use variables for environment-specific values

### State Management

**Terraform State:**
- Remote state backend (S3 + DynamoDB for locking)
- State file encryption
- Separate state per environment
- State locking to prevent concurrent modifications
- Regular state backups

### Docker Best Practices

**Multi-Stage Builds:**
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node healthcheck.js || exit 1
CMD ["node", "dist/main.js"]
```

**Best Practices:**
- Use specific version tags (not `latest`)
- Run as non-root user
- Include health check
- Minimize layer count and image size
- Use `.dockerignore` to exclude unnecessary files
- Scan images for vulnerabilities

### Docker Compose for Local Dev

**docker-compose.yml Structure:**
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: dev
    volumes:
      - postgres-data:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine
  backend:
    build: ./backend
    depends_on:
      - postgres
      - redis
volumes:
  postgres-data:
```

## Disaster Recovery

### Failure Scenarios

**Database Failure:**
- **Detection:** Health check fails, connection errors
- **Automated Response:** Failover to read replica (if available)
- **Manual Procedure:** Restore from backup, update DNS
- **RTO:** 4 hours

**Region Failure:**
- **Detection:** All health checks fail, cloud provider status page
- **Automated Response:** Route traffic to secondary region (if multi-region)
- **Manual Procedure:** Deploy to new region, restore data
- **RTO:** 8 hours

**Data Corruption:**
- **Detection:** Data validation errors, user reports
- **Automated Response:** Alert, stop writes to affected tables
- **Manual Procedure:** Point-in-time recovery to before corruption
- **RTO:** 6 hours

### Detection and Automated Response

**Monitoring for DR Events:**
- Synthetic monitoring from multiple regions
- Health check aggregation
- Cloud provider status integration
- Alert escalation for P0 events

**Automated Responses:**
- Automatic failover for database (if HA configured)
- Traffic rerouting to healthy instances
- Circuit breaker activation
- Alert and page on-call engineer

### Manual Procedures

**Disaster Recovery Runbook:**
1. Assess scope and severity
2. Activate incident response team
3. Execute recovery procedure (documented per scenario)
4. Communicate status to stakeholders
5. Verify recovery (health checks, smoke tests)
6. Monitor for stability
7. Conduct post-mortem

### Communication Plans

**Stakeholder Notification:**
- **P0 Incident:** Immediate notification (phone, Slack, email)
- **Status Page:** Update every 30 minutes during incident
- **Post-Incident:** Summary within 24 hours, detailed post-mortem within 1 week

**Communication Channels:**
- Status page for external users
- Slack incident channel for internal coordination
- Email for executive updates

## Load Testing

### Test Scenarios

**Baseline Test:**
- **Purpose:** Establish normal performance metrics
- **Load:** Average expected load (e.g., 100 req/s)
- **Duration:** 10 minutes
- **Success Criteria:** P95 latency < 500ms, error rate < 0.1%

**Stress Test:**
- **Purpose:** Find breaking point
- **Load:** Gradually increase until system fails
- **Duration:** 30 minutes
- **Success Criteria:** Graceful degradation, no data corruption

**Spike Test:**
- **Purpose:** Test sudden traffic bursts
- **Load:** Sudden 5x spike for 2 minutes
- **Duration:** 15 minutes total
- **Success Criteria:** Auto-scaling activates, no errors

**Soak Test:**
- **Purpose:** Identify memory leaks and stability issues
- **Load:** Sustained average load
- **Duration:** 4 hours
- **Success Criteria:** No memory increase, stable performance

**Chaos Test:**
- **Purpose:** Validate resilience to failures
- **Scenarios:** Kill random instances, inject network latency, fill disk
- **Duration:** 30 minutes
- **Success Criteria:** System recovers, no data loss

### Success Criteria

**Performance Targets:**
- P95 response time < 500ms
- P99 response time < 1s
- Error rate < 0.1%
- Throughput meets business requirements

**Resilience Targets:**
- Automatic recovery from instance failures
- No data loss during failures
- Graceful degradation under overload
- Alert triggering for anomalies

---

**Note:** These standards should be adapted based on specific infrastructure requirements and organizational constraints. Review and update quarterly.
