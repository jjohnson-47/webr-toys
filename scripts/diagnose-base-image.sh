#!/bin/bash
# Diagnose Docker Base Image Issues
# 
# This script helps identify why the base image isn't accessible
# without requiring a full Docker environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Configuration
BASE_IMAGE="ghcr.io/jjohnson-47/webr-toys/hub-base:latest"
REGISTRY="ghcr.io"
REPO_OWNER="jjohnson-47"
REPO_NAME="webr-toys"

check_github_access() {
    log_info "Checking GitHub repository access..."
    
    if command -v gh >/dev/null 2>&1; then
        if gh repo view "$REPO_OWNER/$REPO_NAME" >/dev/null 2>&1; then
            log_success "GitHub repository exists: $REPO_OWNER/$REPO_NAME"
            return 0
        else
            log_warning "GitHub repository not accessible: $REPO_OWNER/$REPO_NAME"
            return 1
        fi
    else
        log_warning "GitHub CLI not available - cannot check repository"
        return 1
    fi
}

check_registry_connectivity() {
    log_info "Checking registry connectivity..."
    
    if curl -s --connect-timeout 5 "https://$REGISTRY/v2/" >/dev/null; then
        log_success "Registry is accessible: $REGISTRY"
        return 0
    else
        log_error "Registry not accessible: $REGISTRY"
        return 1
    fi
}

analyze_dockerfile() {
    log_info "Analyzing Dockerfile dependencies..."
    
    local dockerfile="Dockerfile"
    if [ -f "$dockerfile" ]; then
        log_info "Found Dockerfile, checking base image reference..."
        
        local base_ref=$(grep "^FROM" "$dockerfile" | head -1)
        echo "  Base image line: $base_ref"
        
        # Check if it's a private registry
        if echo "$base_ref" | grep -q "ghcr.io"; then
            log_warning "Using private GitHub Container Registry image"
            echo "  This requires authentication and the image must exist"
        fi
        
        # Check if there's a fallback
        if [ -f "Dockerfile.fallback" ]; then
            log_success "Fallback Dockerfile available"
        else
            log_warning "No fallback Dockerfile found"
        fi
    else
        log_error "No Dockerfile found"
    fi
}

suggest_solutions() {
    log_info "Suggested solutions:"
    echo
    echo "1. 🔧 Check if the base image exists:"
    echo "   • Visit: https://github.com/$REPO_OWNER/$REPO_NAME/pkgs/container/$REPO_NAME"
    echo "   • Verify the 'latest' tag exists"
    echo
    echo "2. 🔐 Set up authentication (if image is private):"
    echo "   export GITHUB_TOKEN=your_personal_access_token"
    echo "   export GITHUB_ACTOR=$REPO_OWNER"
    echo
    echo "3. 🐳 Use fallback Dockerfile:"
    echo "   docker build -f Dockerfile.fallback -t webr-toys:local ."
    echo
    echo "4. 🔄 Update base image reference:"
    echo "   • Change to a public base image (ubuntu:22.04)"
    echo "   • Update to correct private image path"
    echo "   • Use a specific tag instead of 'latest'"
    echo
    echo "5. 🏗️ Use smart build script:"
    echo "   ./scripts/smart-docker-build.sh"
    echo "   (automatically handles fallback)"
}

main() {
    log_info "🔍 Diagnosing Docker Base Image Issues"
    log_info "Base image: $BASE_IMAGE"
    echo
    
    # Check various aspects
    check_registry_connectivity
    echo
    
    check_github_access
    echo
    
    analyze_dockerfile
    echo
    
    suggest_solutions
}

main "$@"