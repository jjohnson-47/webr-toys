library(testthat)

test_that("basic functionality works", {
  expect_equal(2 + 2, 4)
  
  # Test multiple possible paths for key files
  api_paths <- c("api/plumber.R", "../../api/plumber.R")
  api_found <- any(sapply(api_paths, file.exists))
  expect_true(api_found, "API file should be found")
  
  utils_paths <- c("tests/contract/utils-schema.R", "utils-schema.R")
  utils_found <- any(sapply(utils_paths, file.exists))
  expect_true(utils_found, "Utils file should be found")
})

test_that("R packages are available", {
  expect_true(requireNamespace("plumber", quietly = TRUE))
  expect_true(requireNamespace("jsonlite", quietly = TRUE))
  expect_true(requireNamespace("testthat", quietly = TRUE))
})
