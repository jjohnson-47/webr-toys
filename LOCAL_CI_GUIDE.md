# Local CI Testing Guide with act + Lima

## 🎯 **What We Learned**

### **Root Causes of CI Failures:**
1. **Missing system dependencies** - `libssl-dev` for R packages like `httr`
2. **R package installation permissions** - needed proper library paths
3. **Background process failures** - `callr::r_bg()` couldn't find packages
4. **File path resolution** - tests running from different working directories
5. **API server startup** - Plumber API couldn't load required libraries

### **Key Insights:**
- **Local testing with Lima/act saved hours** vs waiting for GitHub Actions
- **R background processes need explicit library path setup**
- **File path assumptions break in CI environments**
- **System dependencies must match exactly between local and CI**

## 🛠️ **Improved act Workflow**

### **Setup (One Time):**
```bash
# Configure act with proper settings
mkdir -p "$HOME/Library/Application Support/act"
cat > "$HOME/Library/Application Support/act/actrc" << 'EOF'
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--container-architecture linux/amd64
--artifact-server-path /tmp/artifacts
EOF
```

### **Usage Patterns:**

#### **1. Quick Package Testing:**
```bash
./local-act-test.sh packages
```
Tests only R package installation - fastest feedback.

#### **2. Contract Test Debugging:**
```bash
./local-act-test.sh contracts  
```
Tests API functionality and schema validation.

#### **3. Full CI Simulation:**
```bash
./local-act-test.sh ci
```
Runs complete GitHub Actions workflow locally.

#### **4. Comprehensive Testing:**
```bash
./local-act-test.sh all
```
Runs packages → contracts → CI workflow in sequence.

## 📋 **Debugging Checklist**

When CI fails, run locally in this order:

### **Step 1: Basic Validation**
```bash
limactl shell act-runner "cd /path/to/repo && Rscript -e 'library(testthat); testthat::test_dir(\"tests/contract\", pattern=\"test-simple\")'"
```

### **Step 2: Background Process Testing**
```bash
limactl shell act-runner "cd /path/to/repo && Rscript -e 'testthat::test_dir(\"tests/contract\", pattern=\"test-debug\")'"
```

### **Step 3: Path Resolution**
```bash
limactl shell act-runner "cd /path/to/repo && Rscript -e 'testthat::test_dir(\"tests/contract\", pattern=\"test-paths\")'"
```

### **Step 4: Full Contract Tests**
```bash
./local-act-test.sh contracts
```

## 🔧 **Best Practices Developed**

### **Test Structure:**
1. **test-simple.R** - Always-passing basic validation
2. **test-debug.R** - Background process and library loading
3. **test-paths.R** - Working directory and file resolution
4. **test-helpers.R** - Shared utilities for robust testing

### **R Package Setup:**
```r
# In background processes, always set library paths
if (Sys.getenv("R_LIBS_USER") != "") {
  .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
}
```

### **File Path Resolution:**
```r
# Use helper functions that try multiple paths
get_schema_path <- function(schema_name) {
  paths_to_try <- c(
    file.path("tests", "contract", "schema", schema_name),
    file.path("schema", schema_name),
    file.path("..", "tests", "contract", "schema", schema_name)
  )
  
  for (path in paths_to_try) {
    if (file.exists(path)) return(path)
  }
  stop(sprintf("Cannot find schema file: %s", schema_name))
}
```

### **Graceful Fallbacks:**
```r
# In API endpoints, handle missing files gracefully
if (!file.exists(expected_file)) {
  return('<!DOCTYPE html><html><body><h1>Test Mode</h1></body></html>')
}
```

## 🚀 **Workflow Integration**

### **Development Cycle:**
1. **Write code** → Test locally with `./local-act-test.sh packages`
2. **Add tests** → Test with `./local-act-test.sh contracts`  
3. **Ready to push** → Final check with `./local-act-test.sh ci`
4. **Push to GitHub** → CI should pass first time

### **Time Savings:**
- **GitHub Actions**: ~7-10 minutes per run
- **Local Lima/act**: ~2-3 minutes per run
- **Feedback loop**: 3-5x faster iteration

## 📊 **Repository Awareness**

### **Current Setup:**
- **Working in**: `/Users/verlyn13/Development/work/webr-toys`
- **Remote**: `git@github-work:jjohnson-47/webr-toys.git`
- **Branch**: `mvp/r-webtoy-hub-bootstrap`

### **File Constraints:**
- ✅ **Can write to**: All subdirectories of current repo
- ✅ **Can modify**: Existing files in repo
- ✅ **Can create**: New files in repo tree
- ❌ **Cannot access**: Parent directories or other repos

## 🎯 **Working Directory Fix Applied**

### **Root Cause Identified:**
- Tests running from `tests/contract` directory instead of project root
- `file.exists("api/plumber.R")` fails because looks for `tests/contract/api/plumber.R`

### **Solution Applied:**
```yaml
# In .github/workflows/ci.yml
jobs:
  build-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ github.workspace }}
```

### **Local Testing Enhanced:**
- Added working directory validation to `./local-act-test.sh contracts`
- Now explicitly checks `pwd` and `api/plumber.R` existence
- Catches working directory misconfigurations early

## 🎯 **Next Steps**

1. **Monitor GitHub Actions** to see if working directory fix resolved issues
2. **Refine test helpers** based on CI results
3. **Document patterns** that work reliably
4. **Create templates** for future R-based tools

The enhanced local testing infrastructure with working directory validation should now catch most CI issues before they reach GitHub Actions! 🎉