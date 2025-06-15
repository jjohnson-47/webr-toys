# Course Pages for STAT A253
# -----------------------------------------------------------------------------
# Serves complete course content pages that integrate with webr-toys tools

#' Serve STAT 253 Chapter 5.1 course page
#' 
#' @get /course/stat253/5-1
#' @serializer html
function() {
  hub_log("Serving STAT 253 Chapter 5.1 course page")
  
  # Read the course page HTML file - handle different working directories
  course_page_path <- if (file.exists("course-pages/stat253-5-1.html")) {
    "course-pages/stat253-5-1.html"
  } else if (file.exists("../course-pages/stat253-5-1.html")) {
    "../course-pages/stat253-5-1.html"
  } else {
    # Return a simple page if file not found (for testing)
    return('<!DOCTYPE html><html><head><title>Test Page</title></head><body><h1>Test Course Page</h1><p>This is a test page for CI testing.</p></body></html>')
  }
  
  page_content <- readLines(course_page_path, warn = FALSE)
  
  # Convert localhost URLs to relative URLs for proper deployment
  page_content <- gsub("http://localhost:8080", "", page_content)
  
  # Join lines back together
  paste(page_content, collapse = "\n")
}

#' Course navigation and directory
#' 
#' @get /course
#' @serializer html 
function() {
  hub_log("Serving course directory")
  
  '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>STAT A253 Course Materials</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; line-height: 1.6; color: #333; max-width: 850px; margin: 0 auto; padding: 20px; background-color: #f9f9f9; }
        h1, h2 { color: #003366; }
        h1 { border-bottom: 2px solid #FFC20E; padding-bottom: 10px; }
        .card { background-color: #ffffff; border: 1px solid #ddd; border-radius: 8px; padding: 25px; margin-bottom: 25px; box-shadow: 0 4px 8px rgba(0,0,0,0.06); }
        .chapter-link { display: block; background: #003366; color: white; padding: 15px 20px; text-decoration: none; border-radius: 5px; margin: 10px 0; }
        .chapter-link:hover { background: #004080; color: white; text-decoration: none; }
        .tool-link { display: inline-block; background: #FFC20E; color: #333; padding: 8px 15px; text-decoration: none; border-radius: 3px; margin: 5px; }
        .tool-link:hover { background: #ffcd3a; text-decoration: none; }
        .coming-soon { opacity: 0.6; background: #ccc !important; color: #666 !important; cursor: not-allowed; }
    </style>
</head>
<body>
    <header>
        <h1>STAT A253: Statistics Course Materials</h1>
        <p style="color: #666; font-style: italic;">Interactive R-Powered Learning Resources</p>
    </header>
    
    <main>
        <section class="card">
            <h2>📚 Available Chapters</h2>
            
            <a href="/course/stat253/5-1" class="chapter-link">
                <strong>Chapter 5.1: Continuous Probability Distributions</strong><br>
                <small>Interactive tutorial with triangular distribution • PDF visualization • Probability calculation</small>
            </a>
            
            <a href="#" class="chapter-link coming-soon">
                <strong>Chapter 5.2: The Uniform Distribution</strong><br>
                <small>Coming soon • Flat distributions • Rectangle area calculations</small>
            </a>
            
            <a href="#" class="chapter-link coming-soon">
                <strong>Chapter 5.3: The Normal Distribution</strong><br>
                <small>Coming soon • Bell curves • Z-scores and standardization</small>
            </a>
        </section>
        
        <section class="card">
            <h2>🛠️ Interactive Tools</h2>
            <p>Direct access to individual R-powered tools:</p>
            
            <a href="/tutorial" class="tool-link">📊 PDF Tutorial</a>
            <a href="/tutorial/pdf-plot" class="tool-link">📈 Plot Generator</a>
            <a href="/tutorial/calculate-probability" class="tool-link">🧮 Probability Calculator</a>
            <a href="/tutorial/info" class="tool-link">📋 API Reference</a>
        </section>
        
        <section class="card">
            <h2>🎯 How to Use These Materials</h2>
            <ul>
                <li><strong>In Blackboard:</strong> Each chapter page embeds seamlessly as an iframe</li>
                <li><strong>Interactive Elements:</strong> All tools work directly in your browser - no R installation needed</li>
                <li><strong>Step-by-Step:</strong> Follow the guided examples, then try the practice problems</li>
                <li><strong>Real-Time Feedback:</strong> See calculations and visualizations update instantly</li>
            </ul>
        </section>
        
        <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; text-align: center;">
            <p>University of Alaska Anchorage • Summer 2025</p>
            <p><em>Powered by webr-toys hub-and-spoke architecture</em></p>
        </footer>
    </main>
</body>
</html>'
}