#!/bin/bash

# ===============================================================================
# Ethereum Node Monitoring Setup
# ===============================================================================
# Version: 0.1.0
# Description: Sets up Prometheus and Grafana monitoring for Ethereum nodes
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Define monitoring paths
MONITORING_DIR="${ETH_BASE_DIR}/monitoring"
PROMETHEUS_DIR="${MONITORING_DIR}/prometheus"
GRAFANA_DIR="${MONITORING_DIR}/grafana"

setup_prometheus() {
    echo "Setting up Prometheus..."
    
    # Create directories
    mkdir -p "${PROMETHEUS_DIR}"
    mkdir -p "${PROMETHEUS_DIR}/data"
    
    # Create Prometheus configuration
    cat > "${PROMETHEUS_DIR}/prometheus.yml" << EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'ethereum_node'
    static_configs:
      - targets: ['localhost:${ETH_METRICS_PORT}']
        labels:
          instance: 'execution_client'

  - job_name: 'ethereum_beacon'
    static_configs:
      - targets: ['localhost:${ETH_BEACON_METRICS_PORT}']
        labels:
          instance: 'consensus_client'
EOL

    # Create Prometheus Docker compose
    cat > "${PROMETHEUS_DIR}/docker-compose.yml" << EOL
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: eth_prometheus
    volumes:
      - ${PROMETHEUS_DIR}/prometheus.yml:/etc/prometheus/prometheus.yml
      - ${PROMETHEUS_DIR}/data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    ports:
      - "9090:9090"
    restart: unless-stopped
    networks:
      - monitoring
EOL
}

setup_grafana() {
    echo "Setting up Grafana..."
    
    # Create directories
    mkdir -p "${GRAFANA_DIR}"
    mkdir -p "${GRAFANA_DIR}/data"
    mkdir -p "${GRAFANA_DIR}/provisioning/datasources"
    mkdir -p "${GRAFANA_DIR}/provisioning/dashboards"
    
    # Create Grafana datasource
    cat > "${GRAFANA_DIR}/provisioning/datasources/prometheus.yml" << EOL
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOL

    # Create Grafana Docker compose
    cat > "${GRAFANA_DIR}/docker-compose.yml" << EOL
version: '3.8'
services:
  grafana:
    image: grafana/grafana:latest
    container_name: eth_grafana
    volumes:
      - ${GRAFANA_DIR}/data:/var/lib/grafana
      - ${GRAFANA_DIR}/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    restart: unless-stopped
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge
EOL

    # Download Ethereum dashboards
    curl -o "${GRAFANA_DIR}/provisioning/dashboards/ethereum.json" https://raw.githubusercontent.com/ethereum/ethereum-metrics-exporter/master/dashboards/overview.json
}

setup_monitoring() {
    echo "Setting up Ethereum node monitoring..."
    
    # Create monitoring network
    docker network create monitoring 2>/dev/null || true
    
    # Setup components
    setup_prometheus
    setup_grafana
    
    # Start services
    docker-compose -f "${PROMETHEUS_DIR}/docker-compose.yml" up -d
    docker-compose -f "${GRAFANA_DIR}/docker-compose.yml" up -d
    
    echo "Monitoring setup complete!"
    echo "Grafana available at: http://localhost:3000"
    echo "Default credentials: admin/admin"
    echo "Prometheus available at: http://localhost:9090"
}

# Run setup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_monitoring
fi 