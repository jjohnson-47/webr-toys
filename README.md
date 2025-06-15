# webr-toys

**Hub-enabled R playground** – _MVP branch_

This repository hosts small, embeddable R tools (APIs & widgets) that will be
served through two channels:

1. A container image orchestrated by the **course-tooling hub** (for use inside
   Blackboard Ultra iframes).
2. A static documentation / demo site published via **GitHub Pages** (gh-pages
   branch).

Quickfart (local)
------------------

```bash
# Build & run the container
docker build -t webr-toys:local .
docker run --rm -p 8000:8000 webr-toys:local

# → open http://localhost:8000/ping  👉  {"status":"pong"}
```

Branch policy
-------------

| Branch | Purpose |
|--------|---------|
| `development` | Integration branch used by the hub & CI |
| `mvp/r-webtoy-hub-bootstrap` | Current MVP work (draft PR → development) |

All changes must land via Pull Request; CI enforces lint, unit & contract
tests, plus container image scan.

