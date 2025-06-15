library(testthat)

test_that("file paths are correct", {
  cat("Working directory:", getwd(), "\n")
  cat("Files in current dir:", paste(list.files(), collapse=", "), "\n")
  cat("Files in api/:", paste(list.files("api"), collapse=", "), "\n")
  cat("Files in tests/contract/:", paste(list.files("tests/contract"), collapse=", "), "\n")
  
  expect_true(file.exists("api/plumber.R"))
  expect_true(file.exists("tests/contract/utils-schema.R"))
  expect_true(dir.exists("tests/contract/schema"))
})
