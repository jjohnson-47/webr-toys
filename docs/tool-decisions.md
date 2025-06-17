# Tool Decisions for webr-toys

This document records architectural and tooling decisions made for the webr-toys project, following agentic baseline and Pure Sunshine principles.

## Docker Desktop Configuration

**Date**: 2025-06-16  
**Decision**: Implement agentic baseline-compliant Docker Desktop setup  
**Rationale**: Ensure Docker operations follow Pure Sunshine laws and maintain secrets boundary

### Configuration Applied

| Setting | Value | Rationale |
|---------|-------|-----------|
| **CLI Installation** | User scope (`$HOME/.docker/bin`) | Environment-Variable First (§2.3), no admin rights needed |
| **Default Docker Socket** | Disabled (per-user socket) | Maintains Secrets Boundary (§2.9), prevents privilege creep |
| **Privileged Port Mapping** | Disabled | Prohibits ambient elevation, requires explicit MCP approval |
| **Auto Configuration Check** | Enabled | Self-healing aligns with Principle 4 (meta-cognition) |
| **Data Root** | `$AGENTIC_STATE_ROOT/docker/data` | Keeps all images/volumes within runtime boundaries |

### Implementation Details

1. **Shell Module**: Created `shell/modules/docker.sh` with proper exports:
   ```bash
   export DOCKER_HOST="unix://$AGENTIC_STATE_ROOT/docker/docker.sock"
   export PATH="$HOME/.docker/bin:$PATH"
   ```

2. **Compose Configuration**: Base compose file at `$AGENTIC_ENV_ROOT/compose/base.yml`
   - Network isolation with `agentic` network
   - Volume management within `AGENTIC_STATE_ROOT`
   - Security defaults (no-new-privileges, read-only containers)

3. **Architecture Validation**: Created `scripts/validate-architecture.sh`
   - Validates agentic environment configuration
   - Checks Docker security compliance
   - Verifies project structure and CI configuration

### Security Improvements

- **Socket Isolation**: Docker socket symlinked to `$AGENTIC_STATE_ROOT/docker/docker.sock`
- **No Root Escalation**: All operations run as user
- **MCP Observable**: Docker state fully contained within agentic boundaries
- **CI Guard**: Validation script prevents global socket exposure

### Compliance Status

✅ **Environment-Variable First**: Docker configuration via environment variables  
✅ **Secrets Boundary**: No global socket exposure  
✅ **Runtime Tree**: All Docker state within `AGENTIC_STATE_ROOT`  
✅ **Meta-cognition**: Self-healing configuration checks  
✅ **Documentation ≡ Reality**: All settings explicit and version-controlled  

## Security Scanning Configuration

**Date**: 2025-06-16  
**Decision**: Implement comprehensive vulnerability scanning with Trivy  
**Rationale**: Proactive security posture with quality gates

### Implementation

- **CI Integration**: Trivy scanning in GitHub Actions
- **Quality Gates**: Fail on CRITICAL/HIGH vulnerabilities
- **Multiple Dockerfiles**: 
  - `Dockerfile.fallback`: Standard Ubuntu build
  - `Dockerfile.secure`: Security-hardened with mitigations
- **Smart Build Selection**: Automatic strategy based on commit messages

### Vulnerability Management

- **Analysis Documentation**: `VULNERABILITY_ANALYSIS.md` tracks findings
- **Remediation Strategy**: Systematic approach to security improvements
- **Local Testing**: `scripts/local-trivy-scan.sh` for development workflow

## Architecture Decisions

### Multi-Stage Docker Strategy

**Rationale**: Support different deployment scenarios while maintaining security
- **Development**: Fallback Dockerfile for local testing
- **Production**: Secure Dockerfile with hardening
- **CI/CD**: Smart selection based on base image availability

### Lima CI Environment

**Purpose**: Local emulation of GitHub Actions for faster iteration
- **Features**: Ubuntu 22.04, Docker, R dependencies, persistent cache
- **Security**: Isolated VM environment
- **Integration**: Matches CI environment exactly

## Future Considerations

1. **Distroless Images**: Further attack surface reduction
2. **Automated Patching**: Security update automation
3. **Supply Chain Security**: Signature verification with cosign
4. **SBOM Generation**: Software Bill of Materials tracking

---

*This document follows the agentic principle that "documentation ≡ reality" and will be updated within 24 hours of any architectural changes.*