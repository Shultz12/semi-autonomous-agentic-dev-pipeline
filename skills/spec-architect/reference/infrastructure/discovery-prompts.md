# Infrastructure Discovery Prompts

This document provides structured discovery questions for infrastructure specifications. Use these prompts to gather comprehensive requirements before writing infrastructure specs.

## Core Identity

### What Infrastructure Is Changing?

**Questions:**
- What infrastructure component(s) are being modified? (database, deployment pipeline, monitoring, networking, etc.)
- Is this a new infrastructure component or modification of existing?
- Which environments are affected? (dev, staging, production, all)
- What services/applications depend on this infrastructure?

**Example:**
"We're adding a new database read replica for the production environment to handle increased read traffic from the reporting service."

### Business Driver

**Questions:**
- What business problem does this solve?
- What metrics/KPIs will this improve?
- What happens if we don't implement this?
- Who requested this change and why?

**Example:**
"Current database is experiencing high read load during peak hours, causing P95 latency to exceed 1 second. This affects user experience for report generation. Requested to support 50% more users by next quarter."

### Urgency

**Questions:**
- What is the deadline? (urgent, within 1 week, within 1 month, no rush)
- Is this blocking other work?
- Are there external dependencies or commitments?
- What are the consequences of delay?

**Example:**
"Target: 2 weeks. Not blocking current work, but needed before marketing campaign that expects 50% traffic increase."

## Current vs Target State

### Current Architecture

**Questions:**
- What is the current infrastructure setup?
- What are current performance metrics? (baseline)
- What are current capacity limits?
- What are known pain points or bottlenecks?
- What monitoring exists today?

**Example:**
"Current: Single database instance. Current metrics: 200 req/s, P95 query time 80ms during normal hours, 150ms during peak. Connection pool frequently maxed out during peak."

### Target State

**Questions:**
- What will the infrastructure look like after changes?
- What performance improvements are expected?
- What new capabilities will be available?
- What scalability headroom will this provide?

**Example:**
"Target: Primary database + 2 read replicas. Route all read queries to replicas. Expected: P95 query time < 50ms during peak, support 300 req/s with headroom for 500 req/s."

### Gap Analysis

**Questions:**
- What changes are needed to move from current to target?
- What are the technical challenges?
- What risks are involved?
- What dependencies must be addressed first?

**Example:**
"Gaps: Need to provision read replicas, update connection pooling configuration, modify application code to route reads to replicas, implement replication lag monitoring. Risk: Application code assumes single database, may have hardcoded connection strings."

## Migrations

### Schema Changes

**Questions:**
- What database schema changes are required?
- What tables/columns are being added, modified, or removed?
- Are there any breaking changes?
- Are there constraints or indexes being added?

**Example:**
"Adding `metadata` JSONB column to `tasks` table. Adding GIN index on `metadata` for faster searches. No breaking changes, new column is nullable."

### Data Volume

**Questions:**
- How many rows will be affected?
- What is the table size?
- How long will the migration take?
- Can migration run during business hours?

**Example:**
"Table: 5M rows, 50GB total. Adding nullable column: ~30 seconds. Adding GIN index: ~5 minutes (using CONCURRENTLY). Can run during business hours."

### Zero-Downtime Requirements

**Questions:**
- Is zero-downtime required?
- What is the acceptable downtime window if any?
- Are there maintenance windows available?
- What happens if downtime occurs?

**Example:**
"Zero-downtime required. No maintenance windows available. Any downtime affects paying customers and violates SLA (99.9% uptime)."

### Rollback Plan

**Questions:**
- How can this migration be rolled back?
- How long does rollback take?
- What data loss occurs during rollback?
- When is rollback no longer possible (point of no return)?

**Example:**
"Rollback: DROP INDEX CONCURRENTLY, DROP COLUMN. Rollback time: ~1 minute. No data loss during rollback (column is nullable, no data written yet). Point of no return: After application starts writing to new column."

## Deployment

### Strategy Choice

**Questions:**
- Which deployment strategy is appropriate? (blue-green, canary, rolling)
- Why is this strategy chosen over alternatives?
- What are the resource requirements? (extra servers, infrastructure)
- What is the rollback strategy?

**Example:**
"Canary deployment chosen. Rationale: Database routing change is risky, want gradual rollout. Plan: 5% → 25% → 50% → 100% over 4 hours. Monitor error rates and latency at each stage."

### Health Checks

**Questions:**
- What health checks are needed?
- What indicates a healthy vs unhealthy state?
- How often should health checks run?
- What is the failure threshold?

**Example:**
"Health check: Query read replica and verify replication lag < 1 second. Run every 30 seconds. Fail if 3 consecutive checks fail. Remove replica from pool if unhealthy."

### Rollback Triggers

**Questions:**
- What conditions trigger automatic rollback?
- What conditions trigger manual rollback?
- Who has authority to trigger rollback?
- What is the rollback procedure?

**Example:**
"Automatic rollback: Error rate > 5% for 2 minutes, P95 latency > 2x baseline for 5 minutes. Manual rollback: On-call engineer discretion. Rollback procedure: Revert application to route all queries to primary, no database changes needed."

### Downtime Window

**Questions:**
- Is downtime acceptable? If yes, how much?
- What is the preferred maintenance window?
- What needs to happen during downtime?
- How will users be notified?

**Example:**
"No downtime acceptable. If downtime needed, preferred window: Sunday 2-4 AM UTC (lowest traffic). Notify users 48 hours in advance via email and status page."

## Monitoring

### New Metrics

**Questions:**
- What new metrics need to be collected?
- What are the baselines for these metrics?
- How will metrics be visualized?
- What tools will collect metrics? (Prometheus, CloudWatch, Datadog, etc.)

**Example:**
"New metrics: Replication lag per replica, read vs write query distribution, replica query time. Baseline: Replication lag < 1 second. Tool: CloudWatch with custom metrics. Dashboard: Add replica panel to existing database dashboard."

### Alerting Rules

**Questions:**
- What conditions should trigger alerts?
- What is the alert severity? (P0, P1, P2, P3)
- Who should be notified?
- What is the response procedure?

**Example:**
"Alert: Replication lag > 5 seconds for 2 minutes. Severity: P1. Notify: On-call engineer via PagerDuty. Response: Check replica health, consider removing from pool if lag persists."

### Dashboard Requirements

**Questions:**
- What dashboards need to be created or updated?
- What visualizations are needed? (line charts, gauges, heatmaps)
- Who will use these dashboards? (engineers, PMs, executives)
- What time ranges should be displayed? (1 hour, 24 hours, 7 days)

**Example:**
"Update 'Database Performance' dashboard. Add: Replication lag time series, query distribution pie chart, replica health status gauges. Audience: Engineers and on-call. Time ranges: 1 hour, 24 hours, 7 days."

## Security

### Network Changes

**Questions:**
- What network changes are required?
- What ports need to be opened/closed?
- What security groups or firewall rules need updating?
- Are there any VPN or VPC peering requirements?

**Example:**
"Open database port from application subnet to replica subnet. Update security group to allow traffic from application servers to replicas. No VPN changes needed."

### Secrets Needed

**Questions:**
- What new secrets are required? (passwords, API keys, certificates)
- How will secrets be generated and stored?
- Who has access to these secrets?
- What is the rotation schedule?

**Example:**
"Generate new database password for replica user. Store in secrets manager. Access: Application IAM role only. Rotation: Every 90 days via automated rotation."

### Access Control Updates

**Questions:**
- What IAM roles or permissions need updating?
- Who needs access to new infrastructure?
- What is the principle of least privilege configuration?
- Are there any compliance requirements? (SOC2, HIPAA, GDPR)

**Example:**
"Create read-only database user for application. Grant SELECT only on required tables. Application IAM role gets permission to retrieve secrets. Compliance: Ensure audit logging enabled (SOC2 requirement)."

## Backup & Recovery

### RPO/RTO Targets

**Questions:**
- What is the acceptable data loss? (RPO)
- What is the acceptable downtime? (RTO)
- Are these targets different for this component vs overall system?
- What is the business impact of not meeting these targets?

**Example:**
"RPO: [Project target] (can lose up to X hours of data). RTO: [Project target] (system must be back up within Y hours). Business impact: revenue loss per hour of downtime."

### Backup Strategy Changes

**Questions:**
- What backup changes are needed?
- How often should backups run?
- How long should backups be retained?
- How will backups be tested?

**Example:**
"Read replicas don't need separate backups (primary already backed up). No changes to backup strategy. Continue daily full backups + WAL archiving from primary. Test quarterly restore drill."

## Scaling

### Expected Load Changes

**Questions:**
- What is the expected traffic increase?
- When will the traffic increase occur?
- What are the peak usage patterns?
- What is the growth projection? (next 6 months, 1 year)

**Example:**
"Expected: 50% traffic increase starting next quarter. Peak hours: 9-11 AM weekdays. Growth projection: 100% increase within 1 year (double current traffic)."

### Autoscaling Needs

**Questions:**
- Should this component autoscale?
- What metrics trigger scaling? (CPU, memory, request rate)
- What are the min/max instances?
- What is the scaling cooldown period?

**Example:**
"Replicas should not autoscale (manual scaling). Application tier autoscales on CPU > 70%. Min: 2 instances, Max: 10 instances. Cooldown: 3 minutes scale up, 5 minutes scale down."

### Capacity Planning

**Questions:**
- What is the current capacity utilization?
- What is the headroom after changes?
- When will the next scaling event be needed?
- What are the bottlenecks or limits?

**Example:**
"Current: 80% capacity (200/250 req/s). After replicas: 40% capacity (300/750 req/s). Next scaling: ~6 months at projected growth. Bottleneck: Database connection limits, may need connection pooler in future."

## Testing

### Load Test Scenarios

**Questions:**
- What load tests are needed?
- What is the test traffic pattern? (baseline, stress, spike, soak)
- What are the success criteria?
- When will tests run? (staging, pre-production, production)

**Example:**
"Tests: Baseline (300 req/s for 10 min), Stress (gradual increase to 1000 req/s), Spike (sudden 5x for 2 min). Success: P95 < 50ms, error rate < 0.1%. Run in staging before production rollout."

### Chaos Test Needs

**Questions:**
- What failure scenarios should be tested?
- How will failures be simulated?
- What is the expected system behavior?
- When will chaos tests run?

**Example:**
"Chaos scenarios: Kill one replica, inject 100ms network latency to replica, primary database connection loss. Expected: Application continues serving requests, automatic failover. Run in staging during business hours."

### DR Drill Plans

**Questions:**
- What disaster recovery scenarios should be tested?
- How often should DR drills occur?
- Who participates in drills?
- What is the drill procedure?

**Example:**
"DR drill: Simulate primary database failure, restore from backup, verify data integrity. Frequency: Quarterly. Participants: On-call engineer, database admin, tech lead."

## Communication

### Stakeholder Notification

**Questions:**
- Who needs to be notified about this change?
- What information do they need?
- When should they be notified? (before, during, after)
- How should they be notified? (email, Slack, meeting)

**Example:**
"Notify: Engineering team (Slack, 1 week before), Product team (email, 1 week before), Customers (if downtime, 48 hours before via email and status page). Information: What's changing, expected impact, timeline."

### Downtime Windows

**Questions:**
- Is there any expected downtime?
- What is the maintenance window?
- How will downtime be communicated?
- What is the escalation plan if downtime extends?

**Example:**
"No expected downtime (zero-downtime deployment). If unexpected downtime: Post status page update within 5 minutes, email customers if > 15 minutes, escalate to engineering manager if > 1 hour."

### Status Page Updates

**Questions:**
- Should the status page be updated?
- What is the update frequency during changes?
- What information should be shared publicly?
- Who is responsible for updates?

**Example:**
"Update status page: 'Scheduled maintenance' notice 48 hours before deployment. During deployment: Update every 30 minutes. Post-deployment: 'All systems operational' within 1 hour. Responsible: On-call engineer."

---

## How to Use These Prompts

1. **Start Broad, Then Narrow**: Begin with core identity questions, then dive into relevant sections
2. **Skip Irrelevant Sections**: Not every infrastructure task needs every section (e.g., a monitoring change doesn't need migration questions)
3. **Iterate**: Use answers to ask follow-up questions and clarify ambiguity
4. **Document Assumptions**: If information is missing, document assumptions and validate with stakeholders
5. **Reference Standards**: Cross-reference answers with `standards.md` to ensure compliance

**Example Flow:**
1. Ask core identity questions to understand what's changing
2. Identify relevant sections (e.g., deployment + monitoring for a new service)
3. Ask detailed questions from those sections
4. Clarify ambiguities and document assumptions
5. Write specification using gathered information and referencing standards
