# Docker Setup Clarification

## Current Docker Configurations

### 1. Docker Desktop (Host System)
- **Purpose**: Primary Docker daemon for development work
- **Configuration**: Agentic baseline compliant
- **Socket**: `$AGENTIC_STATE_ROOT/docker/docker.sock` (symlink to `~/.docker/run/docker.sock`)
- **Status**: ✅ Working and configured
- **Use Case**: Direct development, image building, testing

### 2. Lima CI Environment (Previously Configured)
- **Purpose**: Local CI emulation that matches GitHub Actions
- **Configuration**: Ubuntu 22.04 VM with Docker inside
- **Socket**: Internal VM Docker (isolated from host)
- **Status**: ⚠️ Requires socket_vmnet (sudo access needed)
- **Use Case**: Local CI testing without GitHub Actions overhead

### 3. Act (GitHub Actions Local Runner)
- **Purpose**: Run GitHub Actions workflows locally
- **Configuration**: Uses Lima VM's Docker or host Docker
- **Status**: Part of Lima environment
- **Use Case**: Exact GitHub Actions workflow simulation

## Relationship and Usage Strategy

### Current Situation
```
Host (macOS)
├── Docker Desktop (✅ Working, agentic compliant)
│   ├── Can build images directly
│   ├── Can run Trivy scans
│   └── Good for development iteration
│
└── Lima VM (⚠️ Needs sudo for socket_vmnet)
    ├── Ubuntu 22.04 (matches CI exactly)
    ├── Internal Docker daemon
    ├── Act for GitHub Actions simulation
    └── R dependencies pre-installed
```

### Recommended Approach

**For Now (While CI Runs):**
1. **Use Docker Desktop** for immediate testing:
   ```bash
   # Build secure image (if Docker Hub auth works)
   source "$AGENTIC_ENV_ROOT/shell/modules/docker.sh"
   docker build -f Dockerfile.secure -t webr-toys:secure-test .
   
   # Run vulnerability scan
   trivy image --severity CRITICAL,HIGH webr-toys:secure-test
   ```

2. **Monitor CI** for production validation

**For Future (With Lima Working):**
1. **Lima for CI exactness**: Full GitHub Actions simulation
2. **Docker Desktop for speed**: Quick iteration and testing
3. **Hybrid approach**: Develop on Desktop, validate in Lima

### Docker Desktop vs Lima Trade-offs

| Aspect | Docker Desktop | Lima CI |
|--------|---------------|---------|
| **Speed** | Fast (native) | Slower (VM overhead) |
| **Accuracy** | Good (same packages) | Exact (same environment) |
| **Setup** | ✅ Working now | ⚠️ Needs sudo setup |
| **Connectivity** | ⚠️ Docker Hub auth issues | ✅ Usually better in VM |
| **Use Case** | Development iteration | Pre-CI validation |

### Action Plan

1. **Immediate**: Use Docker Desktop for vulnerability testing if possible
2. **Short-term**: Monitor CI results (12+ minutes)
3. **Long-term**: Set up Lima properly for complete local CI workflow

### Lima Setup (When Ready)
```bash
# Fix socket_vmnet (requires user intervention for sudo)
sudo brew services start socket_vmnet

# Start Lima environment
./scripts/lima-ci.sh start

# Build and scan in Lima (exact CI match)
./scripts/lima-ci.sh build
./scripts/lima-ci.sh scan
```

## Summary

We have both Docker Desktop (working, agentic compliant) and Lima CI setup (needs socket_vmnet). For now, Docker Desktop provides fast iteration while we wait for CI. Lima would give us exact CI environment matching but requires sudo setup.

The agentic Docker configuration ensures both environments follow Pure Sunshine principles when properly configured.