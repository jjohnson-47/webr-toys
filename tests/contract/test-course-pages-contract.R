library(testthat)
library(httr)
library(callr)

# Load test utilities
if (file.exists("tests/contract/test-helpers.R")) {
  source("tests/contract/test-helpers.R")
} else if (file.exists("test-helpers.R")) {
  source("test-helpers.R")
} else {
  stop("Cannot find test-helpers.R")
}

# Contract tests for course page endpoints
test_that("/course serves HTML course directory", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/course", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Check content type is HTML
  expect_true(grepl("text/html", headers(res)$`content-type`))
  
  # Check content includes expected elements
  content <- rawToChar(res$content)
  expect_true(grepl("STAT A253", content))
  expect_true(grepl("Chapter 5.1", content))
  expect_true(grepl("Continuous Probability", content))
})

test_that("/course/stat253/5-1 serves Chapter 5.1 page", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/course/stat253/5-1", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Check content type is HTML
  expect_true(grepl("text/html", headers(res)$`content-type`))
  
  # Check content includes expected course elements
  content <- rawToChar(res$content)
  expect_true(grepl("5.1: Continuous Probability Distributions", content))
  expect_true(grepl("triangular distribution", content))
  expect_true(grepl("friction coefficient", content))
  expect_true(grepl("Interactive Tutorial", content))
  expect_true(grepl("iframe", content))  # Should embed the tutorial
})

test_that("Course page URLs are properly formatted", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/course/stat253/5-1", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  content <- rawToChar(res$content)
  
  # URLs should be relative (no localhost) for proper deployment
  expect_false(grepl("http://localhost:8080", content))
  
  # Should contain relative URLs for the tutorial
  expect_true(grepl('src="/tutorial"', content))
})