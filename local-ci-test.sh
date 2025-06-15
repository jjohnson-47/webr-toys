#!/bin/bash
# Local CI Test Script
# Mimics the GitHub Actions CI workflow for faster local testing

set -e  # Exit on any error

echo "🧪 Starting local CI test for webr-toys..."
echo "========================================"

# Check if we're in the Lima environment
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker available"
else
    echo "❌ Docker not available - run this inside Lima VM"
    exit 1
fi

# Step 1: Install system dependencies (if needed)
echo "📦 Installing system dependencies..."
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libsodium-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

# Step 2: Check if R is available
echo "🔍 Checking R installation..."
if ! command -v R >/dev/null 2>&1; then
    echo "📦 Installing R..."
    sudo apt-get install -y r-base r-base-dev
fi

# Step 3: Create user R library directory
echo "📁 Setting up R user library..."
mkdir -p ~/R/library

# Set R_LIBS_USER environment variable
export R_LIBS_USER=~/R/library

# Step 3: Install R packages
echo "📚 Installing R packages..."
Rscript -e "
.libPaths(c('~/R/library', .libPaths()))
options(repos = c(CRAN = 'https://cloud.r-project.org'))
packages <- c('plumber', 'httr', 'jsonlite', 'testthat', 'callr', 'httpuv', 'uuid', 'jsonvalidate', 'ggplot2')
install.packages(packages)

# Verify packages are installed
library(plumber)
library(ggplot2) 
library(testthat)
cat('✅ All R packages installed and loaded successfully!\n')
"

# Step 4: Test R package loading
echo "🧪 Testing R package loading..."
Rscript -e "
library(plumber)
library(ggplot2)
library(jsonlite)
library(testthat)
cat('✅ All R packages loaded successfully!\n')
"

# Step 5: Run contract tests
echo "🔍 Running contract tests..."
if [ -d "tests/contract" ]; then
    Rscript -e "testthat::test_dir('tests/contract')"
else
    echo "No contract tests found, skipping..."
fi

# Step 6: Run unit tests  
echo "🔍 Running unit tests..."
if [ -d "tests" ]; then
    Rscript -e "testthat::test_dir('tests', filter = '^(?!contract/)')"
else
    echo "No unit tests found, skipping..."
fi

# Step 7: Test Docker build (optional)
echo "🐳 Testing Docker build..."
if docker build -t webr-toys-test:local . ; then
    echo "✅ Docker build successful"
    # Cleanup
    docker rmi webr-toys-test:local
else
    echo "❌ Docker build failed"
    exit 1
fi

echo "🎉 Local CI test completed successfully!"
echo "Ready to push to GitHub!"