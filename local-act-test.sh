#!/bin/bash
# Enhanced Local CI Testing with act (Legacy)
# Better replicates GitHub Actions environment
#
# NOTE: For new development, consider using the persistent Lima environment:
#   ./scripts/lima-ci.sh start
#   ./scripts/lima-ci.sh ci
#
# This script remains for backwards compatibility and specific debugging scenarios.

set -e

echo "🚀 Enhanced Local CI Testing with act + Lima (Legacy)"
echo "====================================================="
echo "💡 TIP: Try the new persistent environment: ./scripts/lima-ci.sh start"
echo ""

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
    echo "🔍 Testing contract tests locally with enhanced CI simulation..."
    
    limactl shell act-runner bash -c "
        # Replicate exact CI environment
        export R_LIBS_USER=/home/runner/work/_temp/Library
        export TZ=UTC
        export _R_CHECK_SYSTEM_CLOCK_=FALSE
        export NOT_CRAN=true
        export GITHUB_WORKSPACE=/Users/verlyn13/Development/work/webr-toys
        
        # Create CI-like library directory
        mkdir -p /home/runner/work/_temp/Library
        
        # Change to workspace (like CI does)
        cd /Users/verlyn13/Development/work/webr-toys
        
        # Set up environment exactly like CI
        echo \"=== CI Environment Simulation ===\"
        echo \"Working directory: \$(pwd)\"
        echo \"R_LIBS_USER: \$R_LIBS_USER\"
        echo \"TZ: \$TZ\"
        echo \"GITHUB_WORKSPACE: \$GITHUB_WORKSPACE\"
        echo \"\"
        
        # Run with CI-like settings
        timeout 300 Rscript -e '
        # Set up library paths exactly like CI
        .libPaths(c(\"/home/runner/work/_temp/Library\", \"~/R/library\", .libPaths()))
        
        # Install packages if missing in CI-like location
        required_packages <- c(\"testthat\", \"httr\", \"callr\", \"plumber\", \"jsonlite\", \"httpuv\", \"uuid\", \"jsonvalidate\", \"ggplot2\")
        
        for (pkg in required_packages) {
          if (!requireNamespace(pkg, quietly = TRUE)) {
            cat(\"Installing missing package:\", pkg, \"\n\")
            install.packages(pkg, lib = \"/home/runner/work/_temp/Library\", repos = \"https://cloud.r-project.org\")
          }
        }
        
        # Verify environment
        cat(\"=== Test Environment Verification ===\", \"\n\")
        cat(\"Working directory:\", getwd(), \"\n\")
        cat(\"Library paths:\", paste(.libPaths(), collapse=\"; \"), \"\n\")
        cat(\"api/plumber.R exists:\", file.exists(\"api/plumber.R\"), \"\n\")
        cat(\"tests/contract exists:\", dir.exists(\"tests/contract\"), \"\n\")
        cat(\"Available packages:\", paste(required_packages[sapply(required_packages, requireNamespace, quietly=TRUE)], collapse=\", \"), \"\n\")
        cat(\"\n\")
        
        # Set up working directory defaults (like CI workflow)
        # This ensures tests run from project root
        Sys.setenv(\"GITHUB_WORKSPACE\" = getwd())
        
        # Run tests with increased verbosity and timeout handling
        cat(\"=== Running Contract Tests ===\", \"\n\")
        result <- tryCatch({
          testthat::test_dir(\"tests/contract\", reporter = \"progress\", stop_on_failure = FALSE)
        }, error = function(e) {
          cat(\"Error in test execution:\", e\$message, \"\n\")
          NULL
        })
        
        if (is.null(result)) {
          quit(status = 1)
        }
        '
    "
}

# Function to debug specific test issues
debug_tests() {
    echo "🐛 Debug mode: Analyzing test failures..."
    
    limactl shell act-runner bash -c "
        cd /Users/verlyn13/Development/work/webr-toys
        export R_LIBS_USER=~/R/library
        
        # Run individual test files to isolate issues
        echo \"=== Testing Individual Contract Files ===\"
        
        for test_file in tests/contract/test-*.R; do
            if [[ \$test_file == *\"debug\"* ]] || [[ \$test_file == *\"simple\"* ]] || [[ \$test_file == *\"paths\"* ]]; then
                continue  # Skip diagnostic tests
            fi
            
            echo \"\"
            echo \"📋 Testing: \$test_file\"
            echo \"----------------------------------------\"
            
            timeout 60 Rscript -e \"
            .libPaths(c('~/R/library', .libPaths()))
            library(testthat)
            
            cat('Testing file:', '\$test_file', '\n')
            
            result <- tryCatch({
                test_file('\$test_file', reporter='progress')
            }, error = function(e) {
                cat('ERROR in', '\$test_file', ':', e\$message, '\n')
                NULL
            })
            \" || echo \"❌ TIMEOUT in \$test_file\"
        done
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
    "debug")
        debug_tests
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
        echo "Usage: $0 [packages|contracts|debug|ci-test|ci|docs|all]"
        echo ""
        echo "Options:"
        echo "  packages  - Test R package installation only"
        echo "  contracts - Test contract tests only"
        echo "  debug     - Debug individual test files"
        echo "  ci-test   - Run simplified CI workflow"
        echo "  ci        - Run full CI workflow"
        echo "  docs      - Run documentation workflow"
        echo "  all       - Run comprehensive testing (default)"
        exit 1
        ;;
esac

echo "🎉 Local testing completed!"