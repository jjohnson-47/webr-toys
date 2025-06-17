library(testthat)
library(curl)
library(callr)

# Load test utilities
helper_paths <- c(
  "tests/contract/test-helpers.R",
  "contract/test-helpers.R", 
  "../contract/test-helpers.R"
)

# Force use of custom helper functions for this test
helpers_loaded <- FALSE

if (!helpers_loaded) {
  # Fallback: inline simple helper functions
  get_api_path <- function(filename) {
    paths_to_try <- c(
      file.path("api", filename),
      file.path("..", "api", filename),
      file.path("../../api", filename)
    )
    
    for (path in paths_to_try) {
      if (file.exists(path)) {
        return(path)
      }
    }
    
    stop(sprintf("Cannot find API file: %s", filename))
  }
  
  start_test_api <- function(port) {
    api_path <- get_api_path("plumber.R")
    
    callr::r_bg(
      func = function(p, api_file) {
        user_lib <- "~/R/library"
        if (dir.exists(user_lib)) {
          .libPaths(c(user_lib, .libPaths()))
        }
        if (Sys.getenv("R_LIBS_USER") != "") {
          .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
        }
        
        library(plumber)
        cat("Starting API on port", p, "with file", api_file, "\n")
        pr <- plumber::plumb(api_file)
        pr$run(host = "127.0.0.1", port = p, swagger = FALSE)
      },
      args = list(port, api_path),
      supervise = TRUE,
      stdout = "|",
      stderr = "|"
    )
  }
  
  wait_for_api <- function(port, endpoint = "/ping", max_attempts = 40) {
    for (i in seq_len(max_attempts)) {
      Sys.sleep(0.5)
      res <- tryCatch({
        url <- sprintf("http://127.0.0.1:%d%s", port, endpoint)
        handle <- curl::new_handle()
        response <- curl::curl_fetch_memory(url, handle)
        response
      }, error = function(e) {
        if (i %% 10 == 0) cat("Attempt", i, "- connection failed\n")
        NULL
      })
      
      if (!is.null(res) && res$status_code < 500) {
        cat("Server responded after", i, "attempts\n")
        return(res)
      }
    }
    cat("Server failed to respond after", max_attempts, "attempts\n")
    return(NULL)
  }
}

test_that("/ping returns 200 and pong", {
  # Generate random port between 8000-9000
  port <- sample(8000:9000, 1)
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Give a moment for process to start
  Sys.sleep(2)
  
  # Check if process is alive
  if (!proc$is_alive()) {
    cat("Background process died immediately. Exit status:", proc$get_exit_status(), "\n")
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
  } else {
    cat("Background process is alive on port", port, "\n")
  }
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/ping", max_attempts = 40)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(res$status_code, 200)
  
  # Parse and validate response body
  body <- jsonlite::fromJSON(rawToChar(res$content))
  expect_equal(body$status, "pong")
})
