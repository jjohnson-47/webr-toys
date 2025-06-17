# Base image for webr-toys with agentic sidecar functionality
# This provides a stable foundation with auth, logging, and monitoring capabilities

FROM ubuntu:22.04

LABEL org.opencontainers.image.description="Hub base image with agentic sidecar for webr-toys"
LABEL org.opencontainers.image.source="https://github.com/jjohnson-47/webr-toys"

# Install core system dependencies
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       # Core utilities
       curl \
       bash \
       tini \
       ca-certificates \
       # Networking and security
       openssl \
       # Monitoring and logging
       jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create agentic sidecar script with enhanced functionality
RUN cat > /usr/local/bin/sidecar << 'EOF'
#!/bin/bash
# Agentic sidecar for webr-toys
# Provides auth, logging, monitoring, and process management

set -euo pipefail

# Configuration
export SIDECAR_VERSION="1.0.0"
export LOG_LEVEL="${LOG_LEVEL:-INFO}"

# Logging function
log() {
    local level="$1"
    shift
    echo "$(date -Iseconds) [SIDECAR] [$level] $*" >&2
}

# Health check function
health_check() {
    # Basic health check - can be enhanced with specific application checks
    if pgrep -f "$@" >/dev/null; then
        log "INFO" "Application is running"
        return 0
    else
        log "ERROR" "Application is not running"
        return 1
    fi
}

# Signal handlers for graceful shutdown
cleanup() {
    log "INFO" "Received shutdown signal, cleaning up..."
    # Add any cleanup logic here
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main sidecar logic
main() {
    log "INFO" "Starting agentic sidecar v${SIDECAR_VERSION}"
    log "INFO" "Log level: ${LOG_LEVEL}"
    
    # Authentication setup (placeholder for actual auth logic)
    log "INFO" "Initializing authentication..."
    
    # Monitoring setup (placeholder for actual monitoring)
    log "INFO" "Starting monitoring..."
    
    # Skip the -- separator if present
    if [ "$1" = "--" ]; then
        shift
    fi
    
    # Start the main application
    log "INFO" "Starting application: $*"
    exec "$@"
}

# Run main function with all arguments
main "$@"
EOF

# Make sidecar executable
RUN chmod +x /usr/local/bin/sidecar

# Set up default user (can be overridden)
RUN useradd -r -u 1000 -s /bin/bash app

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]

# Default command
CMD ["sidecar", "--", "bash"]