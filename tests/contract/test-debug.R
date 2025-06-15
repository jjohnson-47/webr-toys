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

test_that("can load plumber in background process", {
  # Test if plumber can be loaded in background
  proc <- callr::r_bg(
    func = function() {
      if (Sys.getenv("R_LIBS_USER") != "") {
        .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
      }
      
      cat("Attempting to load plumber...\n")
      library(plumber)
      cat("Plumber loaded successfully!\n")
      
      Sys.sleep(1)
      return("plumber_loaded")
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
