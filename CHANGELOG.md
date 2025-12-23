# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-12-23

### Added

- **Productivity Metrics** in Overview section:
  - Commits - Total git commits created by Claude Code
  - Code Edits - Number of code edit operations performed
  - Lines Added/Removed - Code change tracking
  - Net Lines - Net change in lines of code
  - Lines per Dollar - Code productivity efficiency metric
- **Enhanced Sessions & Activity section** (5 panels):
  - Sessions count (moved from Overview)
  - Active Users count (moved from Overview)
  - Avg Session Length - New metric showing average session duration
  - Active Time - Total active hours
  - Cost per Active Hour - Efficiency metric
- Documentation in README.md noting productivity metrics have limited accuracy

### Changed

- **Overview section reorganization**:
  - Monthly Tokens now positioned beside Monthly Cost for better grouping
  - Removed Sessions and Active Users (moved to Sessions & Activity section)
  - Better visual hierarchy with cost metrics in first row, productivity in second row
- **Cost Analysis section improvements**:
  - Converted bar gauges to sortable tables (Cost by Model, Tokens by Model)
  - Tables auto-sort by value (highest to lowest) for better readability
  - Improved layout with side-by-side comparison tables
- **Dashboard provisioning** set to `editable: false` for infrastructure-as-code workflow

### Removed

- User vs CLI Time pie chart (replaced with Avg Session Length metric)
- Redundant session panels from Overview (consolidated in Sessions & Activity)

### Fixed

- Eliminated blank space in Overview section grid layout
- Proper panel positioning with no gaps (all 24 grid units utilized)

### Technical

- Total panels: 26 (was 17 in v1.0.0)
- Dashboard JSON optimized for better maintainability
- Added CLAUDE.md for AI-assisted development guidance

## [1.0.0] - 2025-12-15

### Added

- Initial release
- Docker Compose stack with OpenTelemetry Collector, Prometheus, and Grafana
- Pre-configured Grafana dashboard with:
  - Cost tracking (30-day totals, hourly rates, per-model breakdown)
  - Token usage analytics (input, output, cache read, cache creation)
  - Cache hit rate monitoring with visual gauge
  - Per-user cost breakdown table
  - Time series charts for cost and token rates
- Convenience script (`start.sh`) for managing the stack
- Auto-restart configuration for Docker Desktop (Windows/WSL/Mac)
- Environment variable configuration via `.env` file
- Comprehensive documentation with troubleshooting guide

### Metrics Supported

- `claude_code_cost_usage_USD_total` - Cost tracking per model/session/user
- `claude_code_token_usage_tokens_total` - Token usage by type
- `claude_code_active_time_seconds_total` - Active session time

[1.1.0]: https://github.com/rommelporras/claude-code-monitoring/releases/tag/v1.1.0
[1.0.0]: https://github.com/rommelporras/claude-code-monitoring/releases/tag/v1.0.0
