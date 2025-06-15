library(testthat)
library(callr)

# Load test helpers
source("test-helpers.R")

test_that("API server starts and stays alive", {
  # Try to start the API on an available port
  port <- 8888
  
  cat("Starting API server on port", port, "\n")
  proc <- start_test_api(port)
  
  # Give it time to start
  Sys.sleep(5)
  
  # Check if process is alive
  if (!proc$is_alive()) {
    cat("\n=== API STARTUP DIAGNOSTIC ===\n")
    cat("Process alive:", proc$is_alive(), "\n")
    cat("Exit status:", proc$get_exit_status(), "\n")
    
    # Try to read any output
    tryCatch({
      stdout_lines <- proc$read_output_lines()
      if (length(stdout_lines) > 0) {
        cat("STDOUT:\n", paste(stdout_lines, collapse="\n"), "\n")
      }
    }, error = function(e) cat("Error reading stdout:", e$message, "\n"))
    
    tryCatch({
      stderr_lines <- proc$read_error_lines()
      if (length(stderr_lines) > 0) {
        cat("STDERR:\n", paste(stderr_lines, collapse="\n"), "\n")
      }
    }, error = function(e) cat("Error reading stderr:", e$message, "\n"))
    
    cat("=== END API DIAGNOSTIC ===\n")
  }
  
  expect_true(proc$is_alive(), "API server should be alive")
  
  # If it's alive, try to make a simple HTTP request
  if (proc$is_alive()) {
    cat("API is alive, testing HTTP connectivity...\n")
    
    # Wait for API to be ready
    response <- wait_for_api(port, "/ping", max_attempts = 10)
    
    if (!is.null(response)) {
      cat("✅ Successfully connected to API\n")
      expect_equal(httr::status_code(response), 200)
    } else {
      cat("❌ Could not connect to API\n")
      expect_true(FALSE, "Should be able to connect to API")
    }
    
    # Clean up
    proc$kill()
  }
})