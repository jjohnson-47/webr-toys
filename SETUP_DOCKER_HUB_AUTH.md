# Docker Hub Authentication Setup Guide

## Current Status ❌
```
Error: 401 Unauthorized on ubuntu:22.04 pull
Cause: Anonymous Docker Hub rate limiting (100 pulls/6 hours shared)
```

## Solution: Personal Access Token Authentication

### Step 1: Create Docker Hub Account & PAT
1. **Sign up/Login**: https://hub.docker.com/
2. **Go to Security Settings**: https://hub.docker.com/settings/security  
3. **Create New Token**:
   - Description: "Local Development & CI"
   - Permissions: "Public Repo Read" (minimum needed)
   - Copy the token: `dckr_pat_xxxxxxxxxx`

### Step 2: Configure Environment Variables
```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export DOCKERHUB_USERNAME="your_docker_username"
export DOCKERHUB_PAT="dckr_pat_xxxxxxxxxx"

# Reload shell or source the profile
source ~/.zshrc  # or exec zsh
```

### Step 3: Test Authentication
```bash
# Load agentic Docker module
source "$AGENTIC_ENV_ROOT/shell/modules/docker.sh"

# Test authentication helper
docker_hub_login

# Expected output:
# 🔐 Authenticating with Docker Hub...
# ✅ Authenticated with Docker Hub as your_username  
# 📊 Quota: 100 pulls/hour (authenticated)
```

### Step 4: Verify Ubuntu Access
```bash
# Should now work without 401 errors
docker pull ubuntu:22.04

# Expected output:
# 22.04: Pulling from library/ubuntu
# Digest: sha256:xxxx
# Status: Downloaded newer image for ubuntu:22.04
```

### Step 5: Test Full Pipeline
```bash
# Build our secure Dockerfile locally
DOCKER_BUILDKIT=0 docker build -f Dockerfile.secure -t webr-toys:secure-local .

# Scan for vulnerabilities
trivy image --severity CRITICAL,HIGH webr-toys:secure-local

# Expected: Successful build and vulnerability report
```

## Quota Comparison

| Authentication | Pulls/Hour | IP Sharing | Notes |
|---------------|------------|------------|-------|
| **Anonymous** | ~17 (100/6h) | ❌ Shared pool | Current blocked state |
| **Authenticated** | 100 | ✅ Personal | 6x improvement |
| **Pro Account** | Unlimited | ✅ Personal | $5/month for heavy usage |

## Integration with Agentic Infrastructure

The updated `shell/modules/docker.sh` includes:
- **`docker_hub_login()`**: Smart authentication with helpful guidance
- **Automatic detection**: Shows quota status and setup instructions
- **Agentic compliance**: Follows Pure Sunshine principles

## Troubleshooting

### Issue: "Authentication failed"
**Cause**: Wrong username or PAT  
**Fix**: Verify credentials at https://hub.docker.com/settings/security

### Issue: "Still getting 401"
**Cause**: Cached anonymous token  
**Fix**: `docker logout && docker_hub_login`

### Issue: "PAT not found"
**Cause**: Environment variables not exported  
**Fix**: Check `echo $DOCKERHUB_USERNAME $DOCKERHUB_PAT`

## Expected Outcome

After setup:
- ✅ **Local Ubuntu builds**: Full Dockerfile.secure testing
- ✅ **Vulnerability scanning**: Exact package-level CVE analysis  
- ✅ **Rapid iteration**: No more 12-minute CI feedback loops
- ✅ **CI consistency**: Same auth mechanism works in GitHub Actions
- ✅ **Rate limit relief**: 100 pulls/hour vs ~17 anonymous

This solves our local infrastructure limitation and enables the fast feedback loop we need for security hardening iteration.

## Next Steps After Authentication

1. **Test Dockerfile.secure locally** - validate our security improvements
2. **Compare vulnerability reports** - Dockerfile.fallback vs Dockerfile.secure  
3. **Iterate security hardening** - use local testing for rapid improvement
4. **Push final version** - with confidence from local validation