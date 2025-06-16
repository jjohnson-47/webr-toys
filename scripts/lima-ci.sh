#!/bin/bash
# Lima CI Environment Management Script for webr-toys
# 
# This script manages a persistent Lima-based CI environment that closely
# emulates GitHub Actions for testing webr-toys locally.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIMA_CONFIG="$PROJECT_ROOT/.lima/webr-toys-ci.yaml"
LIMA_NAME="webr-toys-ci"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_lima() {
    if ! command -v limactl >/dev/null 2>&1; then
        log_error "Lima is not installed. Please install it first:"
        echo "  brew install lima"
        exit 1
    fi
}

check_docker_auth() {
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "GITHUB_TOKEN not set. Docker registry authentication will not work."
        log_info "To enable Docker registry access, set GITHUB_TOKEN:"
        echo "  export GITHUB_TOKEN=your_github_token"
        echo "  Get a token from: https://github.com/settings/tokens"
    fi
}

start_environment() {
    log_info "Starting webr-toys CI environment..."
    
    if limactl list | grep -q "^$LIMA_NAME"; then
        if limactl list | grep "^$LIMA_NAME" | grep -q "Running"; then
            log_success "Environment is already running"
        else
            log_info "Starting existing environment..."
            limactl start "$LIMA_NAME"
        fi
    else
        log_info "Creating new environment from config..."
        limactl start "$LIMA_CONFIG" --name="$LIMA_NAME"
    fi
    
    log_success "Environment is ready!"
    log_info "Connect with: limactl shell $LIMA_NAME"
}

stop_environment() {
    log_info "Stopping webr-toys CI environment..."
    if limactl list | grep -q "^$LIMA_NAME"; then
        limactl stop "$LIMA_NAME"
        log_success "Environment stopped"
    else
        log_warning "Environment is not running"
    fi
}

delete_environment() {
    log_warning "This will permanently delete the CI environment and all cached data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting environment..."
        limactl delete "$LIMA_NAME" || true
        rm -rf "$PROJECT_ROOT/.lima/cache" "$PROJECT_ROOT/.lima/docker"
        log_success "Environment deleted"
    else
        log_info "Cancelled"
    fi
}

shell_environment() {
    if ! limactl list | grep "^$LIMA_NAME" | grep -q "Running"; then
        log_info "Environment is not running. Starting..."
        start_environment
    fi
    
    log_info "Connecting to CI environment..."
    limactl shell "$LIMA_NAME"
}

run_ci() {
    if ! limactl list | grep "^$LIMA_NAME" | grep -q "Running"; then
        log_info "Environment is not running. Starting..."
        start_environment
    fi
    
    log_info "Running CI simulation in Lima environment..."
    limactl shell "$LIMA_NAME" bash -c "wt-ci"
}

run_tests() {
    if ! limactl list | grep "^$LIMA_NAME" | grep -q "Running"; then
        log_info "Environment is not running. Starting..."
        start_environment
    fi
    
    log_info "Running tests in Lima environment..."
    limactl shell "$LIMA_NAME" bash -c "wt-test"
}

build_docker() {
    if ! limactl list | grep "^$LIMA_NAME" | grep -q "Running"; then
        log_info "Environment is not running. Starting..."
        start_environment
    fi
    
    check_docker_auth
    log_info "Building Docker image in Lima environment..."
    
    # Pass GitHub token if available
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        limactl shell "$LIMA_NAME" bash -c "
            export GITHUB_TOKEN='$GITHUB_TOKEN'
            export GITHUB_ACTOR='${GITHUB_ACTOR:-local-ci}'
            wt-docker-login && wt-build
        "
    else
        limactl shell "$LIMA_NAME" bash -c "wt-build"
    fi
}

status_environment() {
    log_info "Lima environment status:"
    if limactl list | grep -q "^$LIMA_NAME"; then
        limactl list | grep "^$LIMA_NAME" || echo "Environment not found"
    else
        echo "Environment '$LIMA_NAME' does not exist"
    fi
    
    echo
    log_info "Cache directory sizes:"
    if [ -d "$PROJECT_ROOT/.lima/cache" ]; then
        du -sh "$PROJECT_ROOT/.lima/cache"/* 2>/dev/null || echo "Cache is empty"
    else
        echo "No cache directory"
    fi
}

show_help() {
    cat << EOF
Lima CI Environment Manager for webr-toys

USAGE:
    $0 <command>

COMMANDS:
    start       Start the CI environment (creates if needed)
    stop        Stop the CI environment
    shell       Connect to the CI environment shell
    delete      Delete the CI environment and all data
    status      Show environment and cache status
    
    ci          Run full CI simulation
    test        Run tests only
    build       Build Docker image (with registry auth if GITHUB_TOKEN set)
    
    help        Show this help message

EXAMPLES:
    # Start the environment and connect
    $0 start
    $0 shell
    
    # Run CI simulation
    export GITHUB_TOKEN=your_token
    $0 ci
    
    # Run tests quickly
    $0 test
    
    # Build Docker image with registry access
    export GITHUB_TOKEN=your_token
    export GITHUB_ACTOR=your_username
    $0 build

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN    Personal access token for GitHub Container Registry
    GITHUB_ACTOR    GitHub username (defaults to 'local-ci')

The environment provides:
- Ubuntu 22.04 (matching GitHub Actions)
- Docker with buildx and registry authentication
- R with all project dependencies pre-installed
- Persistent package cache and Docker layer cache
- Project mounted at /workspace/webr-toys
- GitHub CLI and act for workflow testing

Cache is stored in: $PROJECT_ROOT/.lima/cache
EOF
}

# Main command handling
case "${1:-help}" in
    "start")
        check_lima
        start_environment
        ;;
    "stop")
        check_lima
        stop_environment
        ;;
    "delete")
        check_lima
        delete_environment
        ;;
    "shell")
        check_lima
        shell_environment
        ;;
    "ci")
        check_lima
        run_ci
        ;;
    "test")
        check_lima
        run_tests
        ;;
    "build")
        check_lima
        build_docker
        ;;
    "status")
        check_lima
        status_environment
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac