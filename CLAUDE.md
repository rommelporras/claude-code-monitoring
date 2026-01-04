# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code Monitoring is a Docker-based observability stack for tracking Claude Code CLI usage metrics. The stack receives OpenTelemetry metrics from Claude Code, stores them in Prometheus, and visualizes them in Grafana.

**Architecture Flow:**
```
Claude Code CLI → OTel Collector (:4317) → Prometheus (:9090) → Grafana (:3030)
```

**Author:** Rommel C. Porras (https://rommelporras.com)

## Key Commands

### Stack Management

```bash
# Start/stop/restart the monitoring stack
./start.sh              # Start all containers
./start.sh status       # Check health (containers + HTTP endpoints)
./start.sh logs         # View logs (Ctrl+C to exit)
./start.sh stop         # Stop all containers
./start.sh restart      # Restart all containers

# Direct docker compose commands
docker compose up -d
docker compose down
docker compose logs -f [claude-grafana|claude-prometheus|claude-otel-collector]
docker compose restart claude-grafana
```

### Testing Metrics

```bash
# Verify Prometheus is receiving metrics
curl -s "http://localhost:9090/api/v1/query?query=claude_code_cost_usage_USD_total" | jq

# Check OTel collector is receiving data
docker compose logs -f claude-otel-collector
# Look for: "ExportMetricsServiceRequest"

# Verify Prometheus targets are healthy
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job, health}'
```

### Configuration Changes

After modifying `.env`:
```bash
docker compose down
docker compose up -d
```

After modifying `grafana/provisioning/dashboards/claude-code-dashboard.json`:
```bash
docker compose restart claude-grafana
```

## Architecture Details

### Data Flow

1. **Claude Code CLI** exports metrics via OTLP/gRPC to port 4317
2. **OpenTelemetry Collector** receives metrics and exposes them at `:8889/metrics` in Prometheus format
3. **Prometheus** scrapes the collector every 10 seconds, stores time-series data
4. **Grafana** queries Prometheus and renders the dashboard

### Metric Lifecycle

**CRITICAL:** Metrics are **per-session counters**. When a Claude Code session ends:
- The time series becomes **stale** (no new data points)
- Instant queries (`query`) exclude stale series
- Range queries (`query_range`) still include historical data

**Always use `increase()` or `rate()` for aggregations:**
```promql
# WRONG - excludes ended sessions
sum(claude_code_cost_usage_USD_total)

# CORRECT - includes all sessions in time range
sum(increase(claude_code_cost_usage_USD_total[$__range]))
```

### Available Metrics (Reliable)

| Metric | Labels | Description |
|--------|--------|-------------|
| `claude_code_cost_usage_USD_total` | `model`, `session_id`, `user_id`, `user_email` | Cost in USD per session |
| `claude_code_token_usage_tokens_total` | `model`, `type`, `session_id`, `user_id`, `user_email` | Token usage by type (input/output/cacheRead/cacheCreation) |
| `claude_code_active_time_seconds_total` | `interface`, `session_id`, `user_id`, `user_email` | Active time in seconds (interface=cli/user) |

**Note:** `user_email` is preferred over `user_id` (hash) for display purposes.

### Productivity Metrics (Limited Accuracy)

These metrics are **included in the dashboard** but have known limitations:

| Metric | Labels | Limitation |
|--------|--------|------------|
| `claude_code_commit_count_total` | `session_id`, `user_id` | May not count all commits accurately |
| `claude_code_code_edit_tool_decision_total` | `session_id`, `user_id` | Doesn't count all edit operations |
| `claude_code_lines_of_code_count_total` | `type`, `session_id`, `user_id` | Only counts Edit tool diffs, not Write operations |

**Note:** These provide directional insights but should not be relied upon for precise productivity tracking.

### Metrics Not Available

- `claude_code_pull_request_count_total` - Not emitted by Claude Code
- `claude_code_session_count_total` - Not emitted (derive via `count by (session_id)`)

## Dashboard Configuration

### Critical Dashboard Settings

**File:** `grafana/provisioning/dashboards/dashboard.yml`
```yaml
editable: false  # MUST be false - ensures provisioned file is source of truth
```

When `editable: true`, Grafana saves UI edits to the database and stops using the provisioned file. This breaks the infrastructure-as-code workflow.

### Dashboard JSON Structure

**File:** `grafana/provisioning/dashboards/claude-code-dashboard.json`

**Panel Types Used:**
- `stat` - Single value metrics (Overview, Sessions & Activity)
- `table` - Sortable tabular data (Cost by Model, Tokens by Model, Cost by User)
- `timeseries` - Line charts (Trends)
- `gauge` - Cache hit rate visualization

**Layout System:**
- 24-unit wide grid
- `gridPos`: `{x, y, w, h}` where x=horizontal position, y=vertical row, w=width (1-24), h=height
- Rows are collapsible sections: `"type": "row"`, `"collapsed": false`

**Section Order (by y-coordinate):**
1. Overview (y=0) - Always visible, 11 panels
   - Row 1 (y=1): 5 cost/efficiency panels (Monthly Cost, Monthly Tokens, Cost (Selected), Cost/Hour, Cost per 1M Tokens)
   - Row 2 (y=5): 6 productivity panels (Commits, Code Edits, Lines Added, Lines Removed, Net Lines, Lines per Dollar)
2. Sessions & Activity (y=9) - 5 panels (Sessions, Active Users, Avg Session Length, Active Time, Cost per Active Hour)
3. Trends (y=15) - 2 panels
4. Cost Analysis (y=23) - 3 panels (Cost by Model, Tokens by Model, Cost by User - all tables)
5. Token & Efficiency (y=36) - 6 panels

### Common Dashboard Modifications

**Add a new stat panel:**
```json
{
  "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "thresholds"},
      "thresholds": {"mode": "absolute", "steps": [{"color": "#3274D9", "value": null}]},
      "unit": "short",
      "decimals": 0
    }
  },
  "gridPos": {"h": 4, "w": 4, "x": 0, "y": 1},
  "id": <unique_id>,
  "type": "stat",
  "title": "Panel Title",
  "targets": [{
    "datasource": {"type": "prometheus", "uid": "PBFA97CFB590B2093"},
    "expr": "sum(increase(metric_name[$__range]))",
    "refId": "A"
  }]
}
```

**Add table with auto-sort:**
```json
{
  "type": "table",
  "options": {
    "showHeader": true,
    "sortBy": [{"desc": true, "displayName": "Cost"}]
  },
  "targets": [{
    "expr": "sum by (model) (increase(claude_code_cost_usage_USD_total[$__range]))",
    "format": "table",
    "instant": true
  }],
  "transformations": [{
    "id": "organize",
    "options": {
      "excludeByName": {"Time": true},
      "renameByName": {"model": "Model", "Value": "Cost"}
    }
  }]
}
```

**Note:** Table panels require `format: "table"` and `instant: true` in the query.

## Common Prometheus Queries

**Session count (since sessions aren't directly emitted):**
```promql
count(count by (session_id) (increase(claude_code_cost_usage_USD_total[$__range]) > 0)) or vector(0)
```

**Cache hit rate:**
```promql
sum(increase(claude_code_token_usage_tokens_total{type="cacheRead"}[$__range]))
/
(sum(increase(claude_code_token_usage_tokens_total{type="input"}[$__range])) +
 sum(increase(claude_code_token_usage_tokens_total{type="cacheRead"}[$__range])))
* 100
```

**Cost per active hour:**
```promql
sum(increase(claude_code_cost_usage_USD_total[$__range]))
/
(sum(increase(claude_code_active_time_seconds_total[$__range])) / 3600)
```

**Average session length:**
```promql
sum(increase(claude_code_active_time_seconds_total[$__range]))
/
(count(count by (session_id) (increase(claude_code_cost_usage_USD_total[$__range]) > 0)) or vector(1))
```

## Configuration Files

### Environment Variables (.env)

Optional - all have defaults in `docker-compose.yml`. Common overrides:

```bash
GRAFANA_PORT=3030
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin  # CHANGE IN PRODUCTION
PROMETHEUS_PORT=9090
PROMETHEUS_RETENTION=200h     # ~8 days
OTEL_GRPC_PORT=4317
```

### OpenTelemetry Collector (otel-collector-config.yaml)

Receives OTLP metrics on `:4317`, exports to Prometheus format on `:8889/metrics`.

**DO NOT modify** unless adding additional exporters or processors.

### Prometheus (prometheus.yml)

Scrapes OTel collector every 10 seconds.

**Scrape config:**
```yaml
scrape_configs:
  - job_name: 'claude-otel-collector'
    scrape_interval: 10s
    static_configs:
      - targets: ['claude-otel-collector:8889']
```

## File Structure

```
claude-monitoring/
├── docker-compose.yml              # Main orchestration (3 services)
├── .env.example                    # Configuration template
├── start.sh                        # Convenience management script
├── otel-collector-config.yaml      # OTel config (receives OTLP, exports Prometheus)
├── prometheus.yml                  # Prometheus scrape config
├── grafana/provisioning/
│   ├── datasources/
│   │   └── datasource.yml         # Auto-provision Prometheus datasource
│   └── dashboards/
│       ├── dashboard.yml          # Dashboard provisioning config (editable: false!)
│       └── claude-code-dashboard.json  # Dashboard definition (26 panels)
├── docs/plans/                     # Implementation plans (not committed to repo)
├── CHANGELOG.md                    # Semver changelog
└── README.md                       # User-facing documentation
```

## Design Decisions

### Why Tables Instead of Bar Gauges for Sorting

Bar gauge panels in Grafana **do not support value-based sorting** for multi-series Prometheus data. This is a known limitation (GitHub issues #17245, #27230).

Attempted solutions that failed:
- PromQL `sort_desc()` - Only affects query order, not visual display
- `sortBy` transformation - Doesn't work with instant queries
- `seriesToRows` transformation - Breaks multi-series visualization

**Solution:** Use table panels with `sortBy` option for any data requiring sorted display.

### Dashboard Provisioning Strategy

**`editable: false`** in `dashboard.yml` ensures:
- All changes made in Grafana UI are **ignored** on restart
- Dashboard JSON file is the **single source of truth**
- Infrastructure-as-code workflow is preserved

To make dashboard changes:
1. Edit `claude-code-dashboard.json` directly
2. Restart Grafana: `docker compose restart claude-grafana`
3. Refresh browser

### Metric Label Preferences

Use `user_email` over `user_id` in queries:
```promql
# Preferred - readable email addresses
sum by (user_email) (increase(claude_code_cost_usage_USD_total[$__range]))

# Avoid - cryptic hashes
sum by (user_id) (increase(claude_code_cost_usage_USD_total[$__range]))
```

## Troubleshooting

### Dashboard Changes Not Appearing

1. **Check provisioning setting:**
   ```bash
   grep editable grafana/provisioning/dashboards/dashboard.yml
   # Must show: editable: false
   ```

2. **Verify JSON is valid:**
   ```bash
   jq empty grafana/provisioning/dashboards/claude-code-dashboard.json
   # No output = valid JSON
   ```

3. **Check Grafana logs:**
   ```bash
   docker compose logs claude-grafana | grep -i error
   ```

4. **Force reload:**
   ```bash
   docker compose restart claude-grafana
   # Wait 5 seconds, then hard refresh browser (Ctrl+Shift+R)
   ```

### Panels Showing "No Data"

Common causes:
- No active Claude Code sessions in the selected time range
- Time range too short (some panels need 5-10 minutes of data)
- Metric export interval too long (reduce `OTEL_METRIC_EXPORT_INTERVAL` to 10000ms for testing)

**Verify metrics exist:**
```bash
curl -s "http://localhost:9090/api/v1/query?query=claude_code_cost_usage_USD_total" | jq '.data.result | length'
# Should return number > 0
```

### Table Sort Not Working

Ensure `sortBy` references the **renamed column name**, not the original field:

```json
{
  "options": {
    "sortBy": [{"desc": true, "displayName": "Cost"}]  // After rename
  },
  "transformations": [{
    "id": "organize",
    "options": {
      "renameByName": {"Value": "Cost"}  // Must match sortBy
    }
  }]
}
```

## Version History

See `CHANGELOG.md` for release notes. This project uses semantic versioning.

**Current version:** 1.1.1
- v1.1.1 - Fix container auto-restart on Windows Docker Desktop
- v1.1.0 - Dashboard v2 with improved layout and productivity metrics
- v1.0.0 - Initial release
