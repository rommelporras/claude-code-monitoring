# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/rommelporras/claude-code-monitoring/releases/tag/v1.0.0
