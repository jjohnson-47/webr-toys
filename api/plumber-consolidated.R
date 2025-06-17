# Consolidated Plumber API for testing
library(uuid)

# Hub SDK integration functions (simplified - no external calls)
emit_task_event <- function(event_type, task_id = NULL) {
  if (is.null(task_id)) task_id <- UUIDgenerate()
  return(task_id)
}

hub_log <- function(message) {
  cat(paste(Sys.time(), message, "\n"))
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
#' @get /ping
function() {
  hub_log("Ping endpoint called")
  list(status = "pong")
}

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
    <p>Test course directory page</p>
</body>
</html>'
}

#' Get tutorial information
#' @get /tutorial/info
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
    examples = list(
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
    )
  )
}