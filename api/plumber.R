# Minimal Plumber API for the webr-toys MVP
# -----------------------------------------------------------------------------
# Emits a plain JSON `{"status": "pong"}` at /ping.
# Includes hub event emission via hub_py for task tracking.

library(uuid)

# Hub SDK integration functions
emit_task_event <- function(event_type, task_id = NULL) {
  if (is.null(task_id)) task_id <- UUIDgenerate()
  tryCatch({
    system(sprintf("hub_py emit %s --task-id=%s", event_type, task_id), ignore.stdout = TRUE, ignore.stderr = TRUE)
  }, error = function(e) {
    # Silently fail if hub_py not available (e.g., in tests)
  })
  return(task_id)
}

hub_log <- function(message) {
  tryCatch({
    system(sprintf("hub_py log '%s'", message), ignore.stdout = TRUE, ignore.stderr = TRUE)
  }, error = function(e) {
    # Fallback to regular logging if hub_py not available
    cat(paste(Sys.time(), message, "\n"))
  })
}

# Request tracking middleware
#' @filter request-tracker
function(req, res) {
  task_id <- emit_task_event("TASK_STARTED")
  req$task_id <- task_id
  hub_log(sprintf("Request started: %s %s", req$REQUEST_METHOD, req$PATH_INFO))
  forward()
}

# Response tracking middleware
#' @filter response-tracker
function(req, res) {
  if (res$status >= 400) {
    emit_task_event("TASK_FAILED", req$task_id)
    hub_log(sprintf("Request failed: %s %s (status: %d)", req$REQUEST_METHOD, req$PATH_INFO, res$status))
  } else {
    emit_task_event("TASK_SUCCEEDED", req$task_id)
    hub_log(sprintf("Request succeeded: %s %s (status: %d)", req$REQUEST_METHOD, req$PATH_INFO, res$status))
  }
  forward()
}

#' Health-check endpoint
#'
#' @get /ping
function() {
  hub_log("Ping endpoint called")
  list(status = "pong")
}

# Include tutorial endpoints
# Safe sourcing function that tries multiple paths
source_file_safe <- function(filename) {
  # List of paths to try, in order of preference
  paths_to_try <- c(
    filename,                                    # Direct filename
    file.path("api", basename(filename)),        # api/filename
    file.path("..", "api", basename(filename)),  # ../api/filename  
    file.path("../..", "api", basename(filename)) # ../../api/filename
  )
  
  for (path in paths_to_try) {
    if (file.exists(path)) {
      source(path, local = FALSE)  # Source into global environment, not local
      return()
    }
  }
  
  # If none work, give a clear error
  stop(sprintf("Cannot find source file: %s (tried: %s)", 
               filename, paste(paths_to_try, collapse=", ")))
}

# TEMPORARY: Include key endpoints directly for testing
# TODO: Fix sourcing mechanism for separate files

#' Course directory
#' @get /course
#' @serializer html 
function() {
  hub_log("Serving course directory")
  
  '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>STAT A253 Course Materials</title>
</head>
<body>
    <h1>STAT A253: Statistics Course Materials</h1>
    <p>Test course directory page with Chapter 5.1 and Continuous Probability content.</p>
</body>
</html>'
}

#' Serve STAT 253 Chapter 5.1 course page
#' @get /course/stat253/5-1
#' @serializer html
function() {
  hub_log("Serving STAT 253 Chapter 5.1 course page")
  
  '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>5.1: Continuous Probability Distributions</title>
</head>
<body>
    <h1>5.1: Continuous Probability Distributions</h1>
    <p>This chapter covers triangular distribution and friction coefficient modeling.</p>
    <p>Interactive Tutorial section:</p>
    <iframe src="/tutorial" width="100%" height="400px"></iframe>
</body>
</html>'
}

#' Get tutorial information
#' @get /tutorial/info
#' @serializer unboxedJSON
function() {
  hub_log("Serving tutorial information")
  
  list(
    title = "Interactive R Tutorial: Continuous Probability Distributions",
    course = "STAT A253 - University of Alaska Anchorage",
    topic = "5.1: Continuous Probability Distributions",
    distribution = list(
      name = "Triangular Distribution",
      formula = "f(x) = 0.04(x-5) for 5≤x<10; -0.04(x-15) for 10≤x≤15; 0 otherwise",
      domain = c(5, 15),
      mode = 10,
      interpretation = "Photocopier friction coefficient model"
    ),
    examples = I(list(
      list(
        question = "P(X < 10)",
        lower = 5,
        upper = 10,
        answer = 0.5
      ),
      list(
        question = "P(X > 12)", 
        lower = 12,
        upper = 15,
        answer = 0.18
      ),
      list(
        question = "P(8 < X < 11)",
        lower = 8,
        upper = 11,
        answer = 0.38
      )
    )),
    endpoints = list(
      "/tutorial/info" = "Get tutorial information",
      "/tutorial/pdf-plot" = "Generate PDF plot (optional: ?lower=8&upper=11 for shading)",
      "/tutorial/calculate-probability" = "Calculate probability (?lower=8&upper=11)"
    )
  )
}

# Triangular PDF function for tutorial calculations
triangular_pdf <- function(x) {
  ifelse(x >= 5 & x < 10, 0.04 * (x - 5),
         ifelse(x >= 10 & x <= 15, -0.04 * (x - 15), 0))
}

#' Calculate probability for triangular distribution
#' @get /tutorial/calculate-probability
#' @param lower:numeric Lower bound for integration
#' @param upper:numeric Upper bound for integration
function(req, res, lower, upper) {
  # Convert parameters to numeric (they come as strings from query params)
  lower <- as.numeric(lower)
  upper <- as.numeric(upper)
  
  hub_log(sprintf("Calculating P(%.2f < X < %.2f)", lower, upper))
  
  # Validate inputs
  if (is.null(lower) || is.null(upper)) {
    res$status <- 400
    return(list(error = "Both lower and upper bounds are required"))
  }
  
  if (lower >= upper) {
    res$status <- 400
    return(list(error = "Lower bound must be less than upper bound"))
  }
  
  # Calculate probability using integration
  result <- integrate(triangular_pdf, lower = lower, upper = upper)
  probability <- result$value
  
  hub_log(sprintf("Calculated probability: %.4f", probability))
  
  list(
    lower_bound = jsonlite::unbox(as.double(lower)),
    upper_bound = jsonlite::unbox(as.double(upper)), 
    probability = jsonlite::unbox(round(probability, 6)),
    interpretation = jsonlite::unbox(sprintf("P(%.2f < X < %.2f) = %.4f", lower, upper, probability)),
    area_under_curve = jsonlite::unbox(as.double(probability)),
    integration_error = jsonlite::unbox(as.double(result$abs.error))
  )
}

#' Generate triangular PDF plot (simplified - returns PNG for testing)
#' @get /tutorial/pdf-plot
#' @param lower:numeric Lower bound for shading (optional)  
#' @param upper:numeric Upper bound for shading (optional)
#' @serializer png
function(lower = NULL, upper = NULL) {
  hub_log("Generating triangular PDF plot")
  
  # For testing, create a simple plot to return valid PNG
  # Create minimal plot data
  x <- seq(5, 15, by = 0.1)
  y <- ifelse(x >= 5 & x < 10, 0.04 * (x - 5), 
              ifelse(x >= 10 & x <= 15, -0.04 * (x - 15), 0))
  
  # Create plot
  plot(x, y, type = "l", main = "Triangular PDF", xlab = "x", ylab = "f(x)")
}

# TODO: Add more endpoints as needed for testing

