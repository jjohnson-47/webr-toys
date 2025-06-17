#!/bin/bash
# Local Trivy Vulnerability Scanner
# 
# This script replicates the CI Trivy scanning locally to debug vulnerabilities
# before they reach the CI quality gate

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

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
IMAGE_TAG="${1:-webr-toys:scan-test}"
SCAN_TYPE="${2:-quality-gate}"

install_trivy() {
    if command -v trivy >/dev/null 2>&1; then
        log_success "Trivy already installed: $(trivy --version | head -1)"
        return 0
    fi
    
    log_info "Installing Trivy locally..."
    
    # Install trivy using the official installer
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew >/dev/null 2>&1; then
            brew install trivy
        else
            log_error "Please install Homebrew or install Trivy manually"
            return 1
        fi
    else
        # Linux
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
    
    log_success "Trivy installed successfully"
}

build_test_image() {
    log_info "Building test image for vulnerability scanning..."
    cd "$PROJECT_ROOT"
    
    # Use fallback Dockerfile since it's more likely to work
    if docker build -f Dockerfile.fallback -t "$IMAGE_TAG" .; then
        log_success "Test image built: $IMAGE_TAG"
        return 0
    else
        log_error "Failed to build test image"
        return 1
    fi
}

scan_image_detailed() {
    log_info "Running detailed vulnerability scan..."
    
    echo "🔍 Scanning $IMAGE_TAG for vulnerabilities..."
    echo "=================================================="
    
    # Run comprehensive scan
    trivy image \
        --severity CRITICAL,HIGH,MEDIUM,LOW \
        --format table \
        --quiet \
        "$IMAGE_TAG" || true
    
    echo ""
    log_info "Vulnerability summary:"
    trivy image \
        --severity CRITICAL,HIGH \
        --format json \
        --quiet \
        "$IMAGE_TAG" 2>/dev/null | jq -r '
        if .Results then
            .Results[] | 
            if .Vulnerabilities then
                .Vulnerabilities[] |
                select(.Severity == "CRITICAL" or .Severity == "HIGH") |
                "🚨 \(.Severity): \(.VulnerabilityID) in \(.PkgName) \(.InstalledVersion)"
            else
                empty
            end
        else
            "No vulnerabilities found or scan failed"
        end
    ' 2>/dev/null || echo "No critical/high vulnerabilities found or jq not available"
}

scan_quality_gate() {
    log_info "Running quality gate scan (CI simulation)..."
    
    echo "🛡️ Quality Gate: Testing for CRITICAL/HIGH vulnerabilities..."
    echo "============================================================="
    
    # Replicate exact CI command
    if trivy image \
        --severity CRITICAL,HIGH \
        --ignore-unfixed \
        --vuln-type os,library \
        --exit-code 1 \
        --format table \
        "$IMAGE_TAG"; then
        log_success "Quality gate PASSED - No critical/high vulnerabilities found"
        return 0
    else
        log_error "Quality gate FAILED - Critical/high vulnerabilities detected"
        echo ""
        log_info "💡 This is exactly why CI is failing. Vulnerabilities must be fixed."
        return 1
    fi
}

generate_sarif_report() {
    log_info "Generating SARIF report (like CI does)..."
    
    local sarif_file="$PROJECT_ROOT/trivy-results-local.sarif"
    
    trivy image \
        --format sarif \
        --output "$sarif_file" \
        "$IMAGE_TAG" || true
    
    if [ -f "$sarif_file" ]; then
        log_success "SARIF report generated: $sarif_file"
        
        # Show summary
        if command -v jq >/dev/null 2>&1; then
            local total_issues=$(jq '.runs[0].results | length' "$sarif_file" 2>/dev/null || echo "0")
            log_info "Total issues found: $total_issues"
        fi
    else
        log_warning "SARIF report generation failed"
    fi
}

suggest_fixes() {
    log_info "Vulnerability remediation suggestions:"
    echo ""
    echo "🔧 Common fixes for Ubuntu base images:"
    echo "1. Update base image to latest patch version"
    echo "2. Use 'apt-get upgrade' in Dockerfile for security patches"
    echo "3. Remove unnecessary packages to reduce attack surface"
    echo "4. Use distroless or minimal base images"
    echo "5. Consider using multi-stage builds to exclude build tools"
    echo ""
    echo "🚀 Quick fixes to try:"
    echo "   • Add 'RUN apt-get update && apt-get upgrade -y' to Dockerfile"
    echo "   • Use 'ubuntu:22.04' with latest patches"
    echo "   • Remove packages not needed at runtime"
    echo ""
    echo "🔍 For specific CVE fixes:"
    echo "   • Check Ubuntu security advisories"
    echo "   • Update specific packages mentioned in scan"
    echo "   • Consider alternative packages if available"
}

show_usage() {
    cat << EOF
Local Trivy Vulnerability Scanner

USAGE:
    $0 [image_tag] [scan_type]

ARGUMENTS:
    image_tag    Docker image to scan (default: webr-toys:scan-test)
    scan_type    Type of scan to run:
                 - detailed: Full vulnerability report
                 - quality-gate: CI simulation (CRITICAL/HIGH only)
                 - sarif: Generate SARIF report
                 - all: Run all scan types

EXAMPLES:
    # Quick quality gate test (like CI)
    $0

    # Detailed vulnerability analysis
    $0 webr-toys:test detailed

    # Generate SARIF report
    $0 webr-toys:test sarif

    # Run all scans
    $0 webr-toys:test all

This tool helps debug vulnerability issues locally before they fail in CI.
EOF
}

main() {
    cd "$PROJECT_ROOT"
    
    log_info "🔍 Local Trivy Vulnerability Scanner"
    log_info "Target image: $IMAGE_TAG"
    log_info "Scan type: $SCAN_TYPE"
    echo
    
    # Install Trivy if needed
    if ! install_trivy; then
        exit 1
    fi
    
    # Build image if it doesn't exist
    if ! docker image inspect "$IMAGE_TAG" >/dev/null 2>&1; then
        log_warning "Image $IMAGE_TAG not found, building..."
        if ! build_test_image; then
            exit 1
        fi
    else
        log_success "Using existing image: $IMAGE_TAG"
    fi
    
    echo
    
    # Run appropriate scan
    case "$SCAN_TYPE" in
        "detailed")
            scan_image_detailed
            ;;
        "quality-gate")
            if ! scan_quality_gate; then
                echo
                suggest_fixes
                exit 1
            fi
            ;;
        "sarif")
            generate_sarif_report
            ;;
        "all")
            scan_image_detailed
            echo
            scan_quality_gate || true
            echo
            generate_sarif_report
            echo
            suggest_fixes
            ;;
        *)
            # Default to quality gate
            if ! scan_quality_gate; then
                echo
                suggest_fixes
                exit 1
            fi
            ;;
    esac
    
    echo
    log_success "Scan completed!"
}

# Handle help flag
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main "$@"