#!/bin/bash
# Smart Docker Build Script for webr-toys
# 
# This script intelligently handles Docker base image availability issues by:
# 1. Testing if the base image is accessible
# 2. Using fallback Dockerfile if the base image isn't available
# 3. Providing clear feedback about what's happening

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

# Configuration
BASE_IMAGE="ghcr.io/jjohnson-47/webr-toys/hub-base:latest"
DOCKERFILE_MAIN="$PROJECT_ROOT/Dockerfile"
DOCKERFILE_FALLBACK="$PROJECT_ROOT/Dockerfile.fallback"
IMAGE_TAG="${1:-webr-toys:local}"

test_base_image_access() {
    log_info "Testing access to base image: $BASE_IMAGE"
    
    # First, check if we're logged in to the registry
    if ! docker system info | grep -q "Registry:"; then
        log_warning "Docker not configured or not running"
        return 1
    fi
    
    # Try to get the image manifest without pulling
    if docker manifest inspect "$BASE_IMAGE" >/dev/null 2>&1; then
        log_success "Base image is accessible: $BASE_IMAGE"
        return 0
    else
        log_warning "Base image not accessible: $BASE_IMAGE"
        log_info "This could be due to:"
        echo "  • Image doesn't exist at this location"
        echo "  • Authentication required (set GITHUB_TOKEN)"
        echo "  • Incorrect image name or tag"
        return 1
    fi
}

test_docker_auth() {
    log_info "Testing Docker registry authentication..."
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        log_info "GITHUB_TOKEN is set, testing authentication..."
        if echo "$GITHUB_TOKEN" | docker login ghcr.io -u "${GITHUB_ACTOR:-github-actions}" --password-stdin >/dev/null 2>&1; then
            log_success "Successfully authenticated with ghcr.io"
            return 0
        else
            log_error "Authentication failed with provided GITHUB_TOKEN"
            return 1
        fi
    else
        log_warning "GITHUB_TOKEN not set - cannot test registry authentication"
        log_info "To test private registry access, set:"
        echo "  export GITHUB_TOKEN=your_personal_access_token"
        echo "  export GITHUB_ACTOR=your_github_username"
        return 1
    fi
}

build_with_main_dockerfile() {
    log_info "Building with main Dockerfile (includes hub-base)..."
    docker build -f "$DOCKERFILE_MAIN" -t "$IMAGE_TAG" "$PROJECT_ROOT"
}

build_with_fallback_dockerfile() {
    log_info "Building with fallback Dockerfile (self-contained)..."
    log_info "Using Ubuntu 22.04 standard packages (no PPAs)"
    docker build -f "$DOCKERFILE_FALLBACK" -t "$IMAGE_TAG" "$PROJECT_ROOT"
}

show_usage() {
    cat << EOF
Smart Docker Build Script for webr-toys

USAGE:
    $0 [image_tag]

ARGUMENTS:
    image_tag    Docker image tag (default: webr-toys:local)

ENVIRONMENT VARIABLES:
    GITHUB_TOKEN    Personal access token for GitHub Container Registry
    GITHUB_ACTOR    GitHub username (default: github-actions)

EXAMPLES:
    # Basic build (will auto-detect and fallback if needed)
    $0

    # Build with custom tag
    $0 webr-toys:dev

    # Build with registry authentication
    export GITHUB_TOKEN=your_token
    export GITHUB_ACTOR=your_username
    $0

The script will:
1. Test if the base image (ghcr.io/jjohnson-47/hub-base:latest) is accessible
2. Use the main Dockerfile if base image is available
3. Fall back to Dockerfile.fallback if base image is not accessible
4. Provide clear feedback about what's happening

This ensures builds work regardless of base image availability.
EOF
}

main() {
    cd "$PROJECT_ROOT"
    
    log_info "🐳 Smart Docker Build for webr-toys"
    log_info "Target image: $IMAGE_TAG"
    echo
    
    # Test Docker and registry access
    if test_docker_auth; then
        AUTH_AVAILABLE=true
    else
        AUTH_AVAILABLE=false
    fi
    
    # Test base image access
    if test_base_image_access; then
        # Base image is accessible, use main Dockerfile
        log_info "Using main Dockerfile with hub-base..."
        if build_with_main_dockerfile; then
            log_success "Build completed successfully with hub-base!"
            echo
            log_info "Image built: $IMAGE_TAG"
            log_info "Base image: $BASE_IMAGE (accessible)"
        else
            log_error "Build failed with main Dockerfile"
            log_info "Falling back to self-contained build..."
            if build_with_fallback_dockerfile; then
                log_success "Build completed successfully with fallback!"
                log_warning "Note: Using fallback mode (no agentic sidecar)"
            else
                log_error "Both main and fallback builds failed"
                exit 1
            fi
        fi
    else
        # Base image not accessible, use fallback
        log_warning "Base image not accessible, using fallback Dockerfile..."
        if build_with_fallback_dockerfile; then
            log_success "Build completed successfully with fallback!"
            echo
            log_info "Image built: $IMAGE_TAG"
            log_warning "Note: Using fallback mode (simulated sidecar)"
            echo
            if [ "$AUTH_AVAILABLE" = false ]; then
                log_info "💡 To test with the actual hub-base image:"
                echo "  export GITHUB_TOKEN=your_personal_access_token"
                echo "  export GITHUB_ACTOR=your_github_username"
                echo "  $0"
            fi
        else
            log_error "Fallback build failed"
            exit 1
        fi
    fi
    
    echo
    log_info "🎉 Build completed! You can now run:"
    echo "  docker run -p 8080:8080 $IMAGE_TAG"
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"