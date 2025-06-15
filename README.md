# webr-toys

**Hub-enabled R playground** – _MVP branch_ (testing CI trigger)

This repository hosts small, embeddable R tools (APIs & widgets) that will be
served through two channels:

1. A container image orchestrated by the **course-tooling hub** (for use inside
   Blackboard Ultra iframes).
2. A static documentation / demo site published via **GitHub Pages** (gh-pages
   branch).

## 🚀 Live Demo & Educational Tools

**📚 Complete Course Integration:**
- **[STAT A253 Course Directory](http://localhost:8080/course)** - Full course material browser
- **[Chapter 5.1: Continuous PDFs](http://localhost:8080/course/stat253/5-1)** - Complete lesson with embedded interactive tools
  - Professional course page design with UAA branding
  - Embedded video lectures and interactive R tutorials
  - Step-by-step worked examples with live calculations
  - Practice problems with immediate feedback

**🛠️ Standalone Interactive Tools:**
- **[PDF Tutorial](http://localhost:8080/tutorial)** - Interactive R tutorial interface
  - Visualize probability distributions
  - Calculate probabilities with real-time integration  
  - Work through textbook examples step-by-step

**Development Resources:**
- **[Live Demo Site](https://jjohnson-47.github.io/webr-toys/articles/demo.html)** - Interactive demo with /ping endpoint
- **[API Documentation](https://jjohnson-47.github.io/webr-toys/)** - Full API reference and docs

## 🎓 For Educators: Blackboard Ultra Integration

**Embed in Blackboard Ultra:**
```html
<iframe src="https://your-hub-domain/course/stat253/5-1" 
        width="100%" height="800px" frameborder="0">
</iframe>
```

**Key Benefits:**
- **No R installation** required for students
- **Hub authentication** - students auto-authenticated via Blackboard  
- **Usage tracking** - see which tools students engage with most
- **Scalable** - hub handles load balancing automatically
- **Mobile-friendly** - works on tablets and phones

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

