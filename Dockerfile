# syntax=docker/dockerfile:1

# ------------------------------------------------------------------------------------
# Base image published by the hub.  Contains:
#   • Alpine Linux
#   • agentic sidecar (auth + logging)
#   • curl, bash, hub_py, tini
# ------------------------------------------------------------------------------------
# NOTE: replace tag if the hub publishes a newer version.

FROM ghcr.io/jjohnson-47/hub-base:latest AS base

# ---------------------------
# Install R & minimal packages
# ---------------------------
# We leverage Ubuntu packages because they have pre-built BLAS etc.

USER root

RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       # R dependencies
       r-base \
       r-base-dev \
       r-cran-plumber \
       r-cran-jsonlite \
       r-cran-uuid \
       r-cran-ggplot2 \
       # System library dependencies (libgit2-dev removed - not critical for basic functionality)
       libcurl4-openssl-dev \
       libsodium-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Copy application source
# ---------------------------

WORKDIR /srv/app
COPY api ./api
COPY course-pages ./course-pages
COPY entrypoint.R ./
COPY authz-guard.yaml ./

# ---------------------------
# Expose & launch
# ---------------------------

EXPOSE 8080

# Start the application with sidecar integration
# The sidecar command starts the agentic sidecar (auth + logging) then runs the R application
CMD ["sidecar", "--", "R", "-q", "-f", "/srv/app/entrypoint.R"]
