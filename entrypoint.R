# R Application Entrypoint for Sidecar Integration
# -----------------------------------------------------------------------------
# This entrypoint script configures and starts the Plumber API
# to work with the agentic sidecar (auth + logging) from hub-base image.

cat("Starting R application with sidecar integration...\n")

# Load required libraries
library(plumber)

# Configure environment for sidecar integration
Sys.setenv(
  PLUMBER_HOST = "127.0.0.1",  # Bind to localhost for sidecar proxy
  PLUMBER_PORT = "8000",       # Internal port (sidecar will proxy from 8080)
  SIDECAR_ENABLED = "true"
)

# Source the Plumber API
cat("Loading Plumber API from api/plumber.R...\n")
pr <- plumber::plumb("api/plumber.R")

# Add sidecar-aware logging
pr$setSerializer(plumber::serializer_json())

# Configure for sidecar integration
cat("Configuring API for sidecar proxy integration...\n")
cat("- Internal API port: 8000\n")
cat("- Sidecar will handle external requests on port 8080\n")
cat("- Auth guard policies loaded from authz-guard.yaml\n")

# Start the API
cat("Starting Plumber API...\n")
pr$run(
  host = "127.0.0.1",  # Localhost only - sidecar will handle external access
  port = 8000,
  docs = FALSE         # Disable docs endpoint for security
)