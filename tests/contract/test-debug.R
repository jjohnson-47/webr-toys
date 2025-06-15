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
  
  expect_true(proc$is_alive())
  proc$kill()
  expect_false(proc$is_alive())
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
  expect_true(proc$is_alive())
  proc$kill()
})
