#!/bin/bash
# Enhanced Local CI Testing with act
# Better replicates GitHub Actions environment

set -e

echo "🚀 Enhanced Local CI Testing with act + Lima"
echo "============================================="

# Set up environment variables
export DOCKER_HOST="unix://$HOME/.lima/act-runner/sock/docker.sock"

# Create act configuration if not exists
ACT_CONFIG_DIR="$HOME/Library/Application Support/act"
ACT_CONFIG_FILE="$ACT_CONFIG_DIR/actrc"

if [ ! -f "$ACT_CONFIG_FILE" ]; then
    echo "📝 Creating act configuration..."
    mkdir -p "$ACT_CONFIG_DIR"
    cat > "$ACT_CONFIG_FILE" << 'EOF'
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--container-architecture linux/amd64
--artifact-server-path /tmp/artifacts
EOF
    echo "✅ Act configuration created"
fi

# Function to run specific workflow
run_workflow() {
    local workflow=$1
    local job=$2
    
    echo "🧪 Running workflow: $workflow (job: $job)"
    echo "-------------------------------------------"
    
    if [ -n "$job" ]; then
        act push --container-architecture linux/amd64 --workflows ".github/workflows/$workflow" --job "$job" --verbose
    else
        act push --container-architecture linux/amd64 --workflows ".github/workflows/$workflow" --verbose
    fi
}

# Function to run just R package tests
test_r_packages() {
    echo "📚 Testing R package installation locally..."
    
    limactl shell act-runner bash -c "
        export R_LIBS_USER=~/R/library
        mkdir -p ~/R/library
        
        # Test R package installation
        Rscript -e '
        .libPaths(c(\"~/R/library\", .libPaths()))
        options(repos = c(CRAN = \"https://cloud.r-project.org\"))
        packages <- c(\"plumber\", \"httr\", \"jsonlite\", \"testthat\", \"callr\", \"httpuv\", \"uuid\", \"ggplot2\")
        
        cat(\"Installing packages...\n\")
        install.packages(packages)
        
        cat(\"Testing package loading...\n\")
        library(plumber)
        library(ggplot2)
        library(testthat)
        cat(\"✅ All packages loaded successfully!\n\")
        '
    "
}

# Function to test contract tests specifically
test_contracts() {
    echo "🔍 Testing contract tests locally..."
    
    limactl shell act-runner bash -c "
        export R_LIBS_USER=~/R/library
        cd /Users/verlyn13/Development/work/webr-toys
        
        # Run contract tests with detailed output
        Rscript -e '
        .libPaths(c(\"~/R/library\", .libPaths()))
        
        # Check working directory and files
        cat(\"Working directory:\", getwd(), \"\n\")
        cat(\"Files in tests/contract:\", paste(list.files(\"tests/contract\"), collapse=\", \"), \"\n\")
        
        # Run tests
        testthat::test_dir(\"tests/contract\", reporter=\"progress\")
        '
    "
}

# Parse command line arguments
case "${1:-all}" in
    "packages")
        test_r_packages
        ;;
    "contracts")
        test_contracts
        ;;
    "ci-test")
        run_workflow "ci-test.yml" "test-r-setup"
        ;;
    "ci")
        run_workflow "ci.yml" "build-test"
        ;;
    "docs")
        run_workflow "gh-pages.yml" "docs"
        ;;
    "all")
        echo "🎯 Running comprehensive local testing..."
        echo "1. Testing R packages..."
        test_r_packages
        echo "2. Testing contract tests..."
        test_contracts
        echo "3. Running simplified CI workflow..."
        run_workflow "ci-test.yml" "test-r-setup"
        ;;
    *)
        echo "Usage: $0 [packages|contracts|ci-test|ci|docs|all]"
        echo ""
        echo "Options:"
        echo "  packages  - Test R package installation only"
        echo "  contracts - Test contract tests only"
        echo "  ci-test   - Run simplified CI workflow"
        echo "  ci        - Run full CI workflow"
        echo "  docs      - Run documentation workflow"
        echo "  all       - Run comprehensive testing (default)"
        exit 1
        ;;
esac

echo "🎉 Local testing completed!"