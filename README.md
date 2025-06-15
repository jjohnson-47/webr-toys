# webr-toys

**Hub-enabled R playground** – _MVP branch_

This repository hosts small, embeddable R tools (APIs & widgets) that will be
served through two channels:

1. A container image orchestrated by the **course-tooling hub** (for use inside
   Blackboard Ultra iframes).
2. A static documentation / demo site published via **GitHub Pages** (gh-pages
   branch).

## 🚀 Live Demo

Try the API endpoints in your browser:
- **[Live Demo Site](https://jjohnson-47.github.io/webr-toys/articles/demo.html)** - Interactive demo with /ping endpoint
- **[API Documentation](https://jjohnson-47.github.io/webr-toys/)** - Full API reference and docs

## Quick Start (local)

```bash
# Build & run the container
docker build -t webr-toys:local .
docker run --rm -p 8080:8080 webr-toys:local

# → open http://localhost:8080/ping  👉  {"status":"pong"}
```

**Note:** The container now runs with sidecar auth on port 8080 (was 8000).

Branch policy
-------------

| Branch | Purpose |
|--------|---------|
| `development` | Integration branch used by the hub & CI |
| `mvp/r-webtoy-hub-bootstrap` | Current MVP work (draft PR → development) |

All changes must land via Pull Request; CI enforces lint, unit & contract
tests, plus container image scan.

