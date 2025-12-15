#!/bin/bash
# Claude Code Monitoring - Quick Start Script
# Author: Rommel C. Porras (https://rommelporras.com)
#
# Usage:
#   ./start.sh        # Start all containers
#   ./start.sh status # Check container status
#   ./start.sh logs   # View logs
#   ./start.sh stop   # Stop all containers

set -e

cd "$(dirname "$0")"

case "${1:-start}" in
  start)
    echo "🚀 Starting Claude Code Monitoring stack..."
    docker compose up -d
    echo ""
    echo "✅ Services started!"
    echo ""
    echo "📊 Grafana:    http://localhost:3030 (admin/admin)"
    echo "🔍 Prometheus: http://localhost:9090"
    echo ""
    echo "Waiting for services to be ready..."
    sleep 3
    docker compose ps
    ;;

  status)
    echo "📊 Container Status:"
    docker compose ps
    echo ""
    echo "📈 Service Health:"
    echo -n "Grafana:    "
    curl -s http://localhost:3030/api/health | jq -r '.database' 2>/dev/null && echo "✅ OK" || echo "❌ DOWN"
    echo -n "Prometheus: "
    curl -s http://localhost:9090/-/healthy 2>/dev/null && echo "✅ OK" || echo "❌ DOWN"
    echo -n "OTel:       "
    curl -s http://localhost:8889/metrics 2>/dev/null >/dev/null && echo "✅ OK" || echo "❌ DOWN"
    ;;

  logs)
    echo "📜 Showing logs (Ctrl+C to exit)..."
    docker compose logs -f
    ;;

  stop)
    echo "🛑 Stopping Claude Code Monitoring stack..."
    docker compose stop
    echo "✅ Services stopped"
    ;;

  restart)
    echo "🔄 Restarting Claude Code Monitoring stack..."
    docker compose restart
    echo "✅ Services restarted"
    sleep 2
    docker compose ps
    ;;

  *)
    echo "Usage: $0 {start|status|logs|stop|restart}"
    exit 1
    ;;
esac
