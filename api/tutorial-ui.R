# Interactive Tutorial Web Interface
# -----------------------------------------------------------------------------
# HTML interface for the Continuous PDFs tutorial

#' Serve tutorial web interface
#' 
#' @get /tutorial
#' @serializer html
function() {
  hub_log("Serving tutorial web interface")
  
  '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Interactive R Tutorial: Continuous PDFs</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin-bottom: 30px;
        }
        .section {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
            border-left: 4px solid #007bff;
        }
        .interactive-section {
            background: #fff3cd;
            border-left: 4px solid #ffc107;
        }
        .example {
            background: #e7f3ff;
            border-left: 4px solid #17a2b8;
        }
        .formula {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            font-family: "Courier New", monospace;
            text-align: center;
            margin: 10px 0;
        }
        .controls {
            margin: 15px 0;
        }
        .controls input {
            margin: 5px;
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        .controls button {
            background: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }
        .controls button:hover {
            background: #0056b3;
        }
        .result {
            background: #d1edff;
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
        img {
            max-width: 100%;
            height: auto;
            border: 1px solid #ddd;
            border-radius: 5px;
        }
        .endpoint-info {
            background: #f1f3f4;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Interactive R Tutorial: Continuous Probability Distributions</h1>
        <p>STAT A253 - University of Alaska Anchorage</p>
        <p>Topic 5.1: Understanding PDFs through the Triangular Distribution</p>
    </div>

    <div class="section">
        <h2>📚 Learning Objectives</h2>
        <p>By the end of this tutorial, you will be able to:</p>
        <ul>
            <li><strong>Define:</strong> Translate a piecewise mathematical function into R code</li>
            <li><strong>Visualize:</strong> Create plots of probability density functions</li>
            <li><strong>Calculate:</strong> Use integration to find probabilities (areas under curves)</li>
            <li><strong>Apply:</strong> Solve probability problems for custom distributions</li>
        </ul>
    </div>

    <div class="section">
        <h2>🔢 The Triangular Distribution</h2>
        <p>We are modeling the friction coefficient of a photocopier using this triangular probability density function:</p>
        
        <div class="formula">
            f(x) = 0.04(x-5) for 5 ≤ x < 10<br>
            f(x) = -0.04(x-15) for 10 ≤ x ≤ 15<br>
            f(x) = 0 otherwise
        </div>
        
        <p>This creates a triangular shape with peak at x = 10, representing the most likely friction coefficient.</p>
    </div>

    <div class="section interactive-section">
        <h2>📊 Interactive Visualization</h2>
        <p>Generate a plot of the triangular PDF. Optionally add shading to visualize specific probability regions:</p>
        
        <div class="controls">
            <label>Lower bound (optional): </label>
            <input type="number" id="plotLower" placeholder="e.g. 8" step="0.1" min="5" max="15">
            
            <label>Upper bound (optional): </label>
            <input type="number" id="plotUpper" placeholder="e.g. 11" step="0.1" min="5" max="15">
            
            <button onclick="generatePlot()">Generate Plot</button>
            <button onclick="clearPlot()">Clear Bounds</button>
        </div>
        
        <div id="plotResult"></div>
        
        <div class="endpoint-info">
            API Endpoint: GET /tutorial/pdf-plot?lower=8&upper=11
        </div>
    </div>

    <div class="section interactive-section">
        <h2>🧮 Probability Calculator</h2>
        <p>Calculate the probability (area under the curve) between two bounds:</p>
        
        <div class="controls">
            <label>Lower bound: </label>
            <input type="number" id="calcLower" placeholder="e.g. 8" step="0.1" min="5" max="15" required>
            
            <label>Upper bound: </label>
            <input type="number" id="calcUpper" placeholder="e.g. 11" step="0.1" min="5" max="15" required>
            
            <button onclick="calculateProbability()">Calculate Probability</button>
        </div>
        
        <div id="calcResult"></div>
        
        <div class="endpoint-info">
            API Endpoint: GET /tutorial/calculate-probability?lower=8&upper=11
        </div>
    </div>

    <div class="section example">
        <h2>💡 Try These Examples</h2>
        <p>Click the buttons to see worked examples from your textbook:</p>
        
        <button onclick="runExample(5, 10)">Example A: P(X < 10)</button>
        <button onclick="runExample(12, 15)">Example B: P(X > 12)</button>
        <button onclick="runExample(8, 11)">Example C: P(8 < X < 11)</button>
        <button onclick="runExample(5, 15)">Verify: Total Area = 1</button>
    </div>

    <div class="section">
        <h2>🎯 Key Concepts</h2>
        <ul>
            <li><strong>Probability = Area:</strong> The probability P(a < X < b) equals the area under the PDF curve between a and b</li>
            <li><strong>Integration:</strong> We use calculus (integration) to find areas under continuous curves</li>
            <li><strong>Total Area = 1:</strong> The total area under any PDF must equal 1 (100% probability)</li>
            <li><strong>R Functions:</strong> R\'s <code>integrate()</code> function does the calculus for us</li>
        </ul>
    </div>

    <div class="section">
        <h2>🚀 Next Steps</h2>
        <p>You now understand the fundamental approach for any continuous distribution! In practice, R provides convenient functions like <code>pnorm()</code>, <code>punif()</code>, and <code>pexp()</code> that do this integration automatically for famous distributions. But the principle is always the same: <strong>probability is the area under the PDF curve.</strong></p>
    </div>

    <script>
        function generatePlot() {
            const lower = document.getElementById("plotLower").value;
            const upper = document.getElementById("plotUpper").value;
            
            let url = "/tutorial/pdf-plot";
            if (lower && upper) {
                url += `?lower=${lower}&upper=${upper}`;
            }
            
            document.getElementById("plotResult").innerHTML = 
                `<img src="${url}" alt="Triangular PDF Plot" style="max-width: 100%;">`;
        }
        
        function clearPlot() {
            document.getElementById("plotLower").value = "";
            document.getElementById("plotUpper").value = "";
            generatePlot();
        }
        
        function calculateProbability() {
            const lower = document.getElementById("calcLower").value;
            const upper = document.getElementById("calcUpper").value;
            
            if (!lower || !upper) {
                alert("Please enter both lower and upper bounds");
                return;
            }
            
            fetch(`/tutorial/calculate-probability?lower=${lower}&upper=${upper}`)
                .then(response => response.json())
                .then(data => {
                    if (data.error) {
                        document.getElementById("calcResult").innerHTML = 
                            `<div class="result" style="background: #f8d7da; color: #721c24;">Error: ${data.error}</div>`;
                    } else {
                        document.getElementById("calcResult").innerHTML = 
                            `<div class="result">
                                <h4>Result:</h4>
                                <p><strong>${data.interpretation}</strong></p>
                                <p>Probability: <strong>${data.probability}</strong></p>
                                <p>Area under curve: ${data.area_under_curve}</p>
                                <p><em>Integration error: ±${data.integration_error}</em></p>
                            </div>`;
                    }
                })
                .catch(error => {
                    document.getElementById("calcResult").innerHTML = 
                        `<div class="result" style="background: #f8d7da;">Error: ${error.message}</div>`;
                });
        }
        
        function runExample(lower, upper) {
            document.getElementById("calcLower").value = lower;
            document.getElementById("calcUpper").value = upper;
            calculateProbability();
            
            document.getElementById("plotLower").value = lower;
            document.getElementById("plotUpper").value = upper;
            generatePlot();
        }
        
        // Load initial plot
        generatePlot();
    </script>
</body>
</html>'
}