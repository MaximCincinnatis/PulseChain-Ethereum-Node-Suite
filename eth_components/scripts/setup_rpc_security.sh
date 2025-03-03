#!/bin/bash

# ===============================================================================
# Ethereum RPC Security Setup
# ===============================================================================
# Version: 0.1.0
# Description: Sets up secure RPC access with authentication and rate limiting
# ===============================================================================

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/eth_config.sh"

# Define RPC security paths
RPC_DIR="${ETH_BASE_DIR}/rpc"
NGINX_DIR="${RPC_DIR}/nginx"
AUTH_DIR="${RPC_DIR}/auth"

setup_nginx_config() {
    echo "Setting up Nginx reverse proxy with security features..."
    
    # Create directories
    mkdir -p "${NGINX_DIR}"
    mkdir -p "${AUTH_DIR}"
    
    # Generate strong password for RPC access
    RPC_PASSWORD=$(openssl rand -base64 32)
    echo "admin:$(openssl passwd -apr1 ${RPC_PASSWORD})" > "${AUTH_DIR}/.htpasswd"
    
    # Create Nginx configuration
    cat > "${NGINX_DIR}/nginx.conf" << EOL
worker_processes auto;
events {
    worker_connections 1024;
}

http {
    limit_req_zone \$binary_remote_addr zone=rpc_limit:10m rate=10r/s;
    
    upstream ethereum_node {
        server 127.0.0.1:${ETH_RPC_PORT};
        keepalive 32;
    }
    
    server {
        listen 8545;
        server_name localhost;
        
        # SSL configuration
        ssl_certificate /etc/nginx/ssl/node.crt;
        ssl_certificate_key /etc/nginx/ssl/node.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        
        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-XSS-Protection "1; mode=block" always;
        
        location / {
            # Rate limiting
            limit_req zone=rpc_limit burst=20 nodelay;
            
            # Authentication
            auth_basic "Ethereum Node RPC";
            auth_basic_user_file /etc/nginx/auth/.htpasswd;
            
            # Proxy settings
            proxy_pass http://ethereum_node;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_cache_bypass \$http_upgrade;
            
            # Security measures
            proxy_hide_header X-Powered-By;
            proxy_hide_header Server;
            
            # Only allow specific RPC methods
            if (\$request_method !~ ^(POST|OPTIONS)$) {
                return 403;
            }
        }
    }
}
EOL

    # Generate self-signed SSL certificate
    mkdir -p "${NGINX_DIR}/ssl"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "${NGINX_DIR}/ssl/node.key" \
        -out "${NGINX_DIR}/ssl/node.crt" \
        -subj "/CN=localhost"
    
    # Create Docker compose file
    cat > "${NGINX_DIR}/docker-compose.yml" << EOL
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    container_name: eth_rpc_proxy
    volumes:
      - ${NGINX_DIR}/nginx.conf:/etc/nginx/nginx.conf:ro
      - ${NGINX_DIR}/ssl:/etc/nginx/ssl:ro
      - ${AUTH_DIR}/.htpasswd:/etc/nginx/auth/.htpasswd:ro
    ports:
      - "8545:8545"
    restart: unless-stopped
    networks:
      - ethereum
EOL
}

setup_rpc_security() {
    echo "Setting up RPC security..."
    
    # Setup Nginx configuration
    setup_nginx_config
    
    # Start Nginx proxy
    docker-compose -f "${NGINX_DIR}/docker-compose.yml" up -d
    
    # Save credentials
    echo "RPC Credentials saved to: ${AUTH_DIR}/credentials.txt"
    cat > "${AUTH_DIR}/credentials.txt" << EOL
RPC Endpoint: https://localhost:8545
Username: admin
Password: ${RPC_PASSWORD}
EOL
    chmod 600 "${AUTH_DIR}/credentials.txt"
    
    echo "RPC security setup complete!"
    echo "Credentials have been saved to: ${AUTH_DIR}/credentials.txt"
    echo "Please store these credentials securely."
}

# Run setup if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rpc_security
fi 