library(testthat)
library(callr)

test_that("can start simple R background process", {
  # Test if callr works at all
  proc <- callr::r_bg(
    func = function() {
      cat("Background R process started successfully!\n")
      Sys.sleep(1)
      return("success")
    },
    supervise = TRUE,
    stdout = "|",
    stderr = "|"
  )
  
  Sys.sleep(2)
  
  # Capture diagnostic info if process fails
  if (!proc$is_alive()) {
    cat("\n=== BACKGROUND PROCESS DIAGNOSTIC ===\n")
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
    
    cat("=== END DIAGNOSTIC ===\n")
  }
  
  expect_true(proc$is_alive())
  if (proc$is_alive()) {
    proc$kill()
    expect_false(proc$is_alive())
  }
})

test_that("can start actual plumber server in background", {
  # Test if we can start a real Plumber server that stays alive
  source("test-helpers.R")
  
  proc <- callr::r_bg(
    func = function() {
      if (Sys.getenv("R_LIBS_USER") != "") {
        .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
      }
      
      cat("Working directory:", getwd(), "\n")
      cat("Looking for API file...\n")
      
      # Try to find the API file
      api_paths <- c("api/plumber.R", "../../api/plumber.R", "../../../api/plumber.R")
      api_file <- NULL
      
      for (path in api_paths) {
        if (file.exists(path)) {
          api_file <- path
          cat("Found API file at:", path, "\n")
          break
        }
      }
      
      if (is.null(api_file)) {
        cat("ERROR: Could not find api/plumber.R file\n")
        return("api_file_not_found")
      }
      
      cat("Attempting to load plumber...\n")
      library(plumber)
      cat("Plumber loaded successfully!\n")
      
      cat("Creating plumber router from:", api_file, "\n")
      tryCatch({
        pr <- plumber::plumb(api_file)
        cat("Router created successfully!\n")
        cat("Starting server on port 8889...\n")
        # This should be a blocking call that keeps the process alive
        pr$run(host = "127.0.0.1", port = 8889, swagger = FALSE)
      }, error = function(e) {
        cat("ERROR in plumber startup:", e$message, "\n")
        return("plumber_error")
      })
    },
    supervise = TRUE,
    stdout = "|", 
    stderr = "|"
  )
  
  Sys.sleep(3)
  
  # Capture diagnostic info if process fails
  if (!proc$is_alive()) {
    cat("\n=== PLUMBER PROCESS DIAGNOSTIC ===\n")
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
    
    cat("=== END PLUMBER DIAGNOSTIC ===\n")
  }
  
  expect_true(proc$is_alive())
  if (proc$is_alive()) {
    proc$kill()
  }
})
