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
       software-properties-common gnupg curl \
    && add-apt-repository "ppa:cran/libgit2" \
    && apt-get update -y \
    && apt-get install -y --no-install-recommends \
       r-base r-base-dev r-cran-plumber r-cran-jsonlite \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Copy application source
# ---------------------------

WORKDIR /srv/app
COPY api ./api

# ---------------------------
# Expose & launch
# ---------------------------

EXPOSE 8000

# Start the Plumber API under tini so SIGTERM is propagated.
CMD ["tini", "--", "R", "-q", "-e", "pr <- plumber::plumb('api/plumber.R'); pr$run(host='0.0.0.0', port=8000)"]

