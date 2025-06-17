# Test Helper Functions for Contract Tests
# Shared utilities for starting API servers and handling test setup

#' Find API file with fallback paths
#' 
#' @param filename API file name (e.g., "plumber.R")
#' @return Full path to API file
get_api_path <- function(filename) {
  paths_to_try <- c(
    file.path("api", filename),
    file.path("..", "..", "api", filename),
    file.path("../../api", filename)
  )
  
  for (path in paths_to_try) {
    if (file.exists(path)) {
      return(path)
    }
  }
  
  stop(sprintf("Cannot find API file: %s", filename))
}

#' Start API server in background for testing
#' 
#' @param port Port number to start server on
#' @return callr process object
start_test_api <- function(port) {
  # Find the API file path before starting background process
  api_path <- get_api_path("plumber.R")
  
  callr::r_bg(
    func = function(p, api_file) {
      # Set up library paths for background process - ensure packages are available
      user_lib <- "~/R/library"
      if (dir.exists(user_lib)) {
        .libPaths(c(user_lib, .libPaths()))
      }
      if (Sys.getenv("R_LIBS_USER") != "") {
        .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
      }
      
      cat("Library paths:", paste(.libPaths(), collapse="; "), "\n")
      cat("Working directory:", getwd(), "\n")
      
      # Load required libraries with error handling
      tryCatch({
        library(plumber)
        cat("✓ plumber loaded\n")
      }, error = function(e) {
        cat("✗ plumber failed:", e$message, "\n")
        stop("plumber package not available")
      })
      
      tryCatch({
        library(jsonlite) 
        cat("✓ jsonlite loaded\n")
      }, error = function(e) {
        cat("✗ jsonlite failed:", e$message, "\n")
        stop("jsonlite package not available")
      })
      
      # Load optional libraries
      if (requireNamespace("uuid", quietly = TRUE)) {
        library(uuid)
        cat("✓ uuid loaded\n")
      } else {
        cat("⚠ uuid not available\n")
      }
      
      if (requireNamespace("ggplot2", quietly = TRUE)) {
        library(ggplot2)
        cat("✓ ggplot2 loaded\n")
      } else {
        cat("⚠ ggplot2 not available\n")
      }
      
      cat("Starting API on port", p, "with file", api_file, "\n")
      tryCatch({
        pr <- plumber::plumb(api_file)
        pr$run(host = "127.0.0.1", port = p, swagger = FALSE)
      }, error = function(e) {
        cat("Error starting API:", e$message, "\n")
        stop(e)
      })
    },
    args = list(port, api_path),
    supervise = TRUE,
    stdout = "|",
    stderr = "|"
  )
}

#' Wait for API server to respond
#' 
#' @param port Port to test
#' @param endpoint Endpoint to test (default: "/ping")
#' @param max_attempts Maximum number of attempts (default: 20)
#' @return HTTP response object or NULL if failed
wait_for_api <- function(port, endpoint = "/ping", max_attempts = 20) {
  for (i in seq_len(max_attempts)) {
    Sys.sleep(0.5)
    res <- tryCatch(
      httr::GET(sprintf("http://127.0.0.1:%d%s", port, endpoint)),
      error = function(e) NULL
    )
    if (!is.null(res) && httr::status_code(res) < 500) {
      return(res)
    }
  }
  return(NULL)
}

#' Get schema path with fallback handling
#' 
#' @param schema_name Schema file name (e.g., "ping-response.json")
#' @return Full path to schema file
get_schema_path <- function(schema_name) {
  paths_to_try <- c(
    file.path("schema", schema_name),
    file.path("tests", "contract", "schema", schema_name),
    file.path("..", "..", "tests", "contract", "schema", schema_name),
    file.path("../../tests/contract/schema", schema_name)
  )
  
  for (path in paths_to_try) {
    if (file.exists(path)) {
      return(path)
    }
  }
  
  stop(sprintf("Cannot find schema file: %s", schema_name))
}