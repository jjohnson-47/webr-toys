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
      source(path, local = TRUE)
      return()
    }
  }
  
  # If none work, give a clear error
  stop(sprintf("Cannot find source file: %s (tried: %s)", 
               filename, paste(paths_to_try, collapse=", ")))
}

source_file_safe("tutorial-pdfs.R")
source_file_safe("tutorial-ui.R")
source_file_safe("course-pages.R")

