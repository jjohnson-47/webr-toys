#!/usr/bin/env bash
# scripts/validate-architecture.sh
# Architecture validation for agentic baseline compliance
# 
# This script validates that the development environment follows
# Pure Sunshine principles and agentic baseline requirements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Architecture validation checks
validate_agentic_environment() {
    local violations=()
    
    log_info "Validating agentic environment configuration..."
    
    # Check required environment variables
    if [[ -z "${AGENTIC_STATE_ROOT:-}" ]]; then
        violations+=("AGENTIC_STATE_ROOT not set")
    fi
    
    if [[ -z "${AGENTIC_ENV_ROOT:-}" ]]; then
        violations+=("AGENTIC_ENV_ROOT not set")
    fi
    
    # Check agentic directories exist
    if [[ -n "${AGENTIC_STATE_ROOT:-}" ]] && [[ ! -d "$AGENTIC_STATE_ROOT" ]]; then
        violations+=("AGENTIC_STATE_ROOT directory does not exist: $AGENTIC_STATE_ROOT")
    fi
    
    if [[ -n "${AGENTIC_ENV_ROOT:-}" ]] && [[ ! -d "$AGENTIC_ENV_ROOT" ]]; then
        violations+=("AGENTIC_ENV_ROOT directory does not exist: $AGENTIC_ENV_ROOT")
    fi
    
    return ${#violations[@]}
}

validate_docker_security() {
    local violations=()
    
    log_info "Validating Docker security configuration..."
    
    # Check for global socket exposure (Principle: Secrets Boundary)
    if [[ -S /var/run/docker.sock ]] && [[ "$(stat -f '%u' /var/run/docker.sock 2>/dev/null)" -ne 0 ]]; then
        violations+=("VIOLATION: global docker.sock exposed to non-root users")
    fi
    
    # Check Docker host configuration
    if [[ -n "${DOCKER_HOST:-}" ]] && [[ "$DOCKER_HOST" != *"$AGENTIC_STATE_ROOT"* ]]; then
        violations+=("DOCKER_HOST not pointing to agentic socket: $DOCKER_HOST")
    fi
    
    # Check if Docker CLI is in user scope
    if command -v docker >/dev/null 2>&1; then
        local docker_path
        docker_path=$(which docker)
        if [[ "$docker_path" != *".docker/bin"* ]] && [[ "$docker_path" != *"$HOME"* ]]; then
            log_warning "Docker CLI not in user scope: $docker_path"
        fi
    fi
    
    return ${#violations[@]}
}

validate_project_structure() {
    local violations=()
    
    log_info "Validating project structure..."
    
    # Check for required project files
    local required_files=(
        "README.md"
        "Dockerfile.fallback"
        "Dockerfile.secure"
        ".github/workflows/ci.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$file" ]]; then
            violations+=("Required file missing: $file")
        fi
    done
    
    # Check for security-related files
    if [[ -f "$PROJECT_ROOT/VULNERABILITY_ANALYSIS.md" ]]; then
        log_success "Vulnerability analysis documentation present"
    else
        log_warning "Vulnerability analysis documentation missing"
    fi
    
    return ${#violations[@]}
}

validate_ci_configuration() {
    local violations=()
    
    log_info "Validating CI/CD configuration..."
    
    # Check if CI has proper security scanning
    if [[ -f "$PROJECT_ROOT/.github/workflows/ci.yml" ]]; then
        if grep -q "trivy" "$PROJECT_ROOT/.github/workflows/ci.yml"; then
            log_success "Trivy security scanning configured"
        else
            violations+=("No Trivy security scanning in CI")
        fi
        
        if grep -q "security-events: write" "$PROJECT_ROOT/.github/workflows/ci.yml"; then
            log_success "Security events permissions configured"
        else
            violations+=("Missing security-events permissions in CI")
        fi
    fi
    
    return ${#violations[@]}
}

# Main validation function
main() {
    log_info "🔍 Starting architecture validation for webr-toys"
    echo
    
    local total_violations=0
    local check_functions=(
        "validate_agentic_environment"
        "validate_docker_security"
        "validate_project_structure"
        "validate_ci_configuration"
    )
    
    for check_func in "${check_functions[@]}"; do
        if ! "$check_func"; then
            ((total_violations += $?))
        fi
        echo
    done
    
    # Final report
    if [[ $total_violations -eq 0 ]]; then
        log_success "🎉 All architecture validation checks passed!"
        log_info "Project follows agentic baseline and Pure Sunshine principles"
        exit 0
    else
        log_error "❌ Architecture validation failed with $total_violations violations"
        log_info "Please fix the violations above to ensure compliance"
        exit 1
    fi
}

# Show usage if requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << 'EOF'
Architecture Validation Script for webr-toys

USAGE:
    ./scripts/validate-architecture.sh

DESCRIPTION:
    Validates that the development environment and project structure
    follow agentic baseline and Pure Sunshine principles:
    
    • Agentic environment configuration
    • Docker security and rootless setup
    • Project structure and required files
    • CI/CD security configuration
    
COMPLIANCE CHECKS:
    ✓ AGENTIC_STATE_ROOT and AGENTIC_ENV_ROOT configured
    ✓ Docker socket within agentic boundaries
    ✓ No global docker.sock exposure
    ✓ Required project files present
    ✓ Security scanning configured in CI
    ✓ Proper permissions and secrets handling

EXIT CODES:
    0 - All checks passed
    1 - One or more violations found
EOF
    exit 0
fi

# Run validation
main "$@"