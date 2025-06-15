library(testthat)

test_that("file paths are correct", {
  cat("Working directory:", getwd(), "\n")
  cat("Files in current dir:", paste(list.files(), collapse=", "), "\n")
  
  # Test multiple possible paths for key files
  api_paths <- c("api/plumber.R", "../../api/plumber.R")
  api_found <- any(sapply(api_paths, file.exists))
  cat("API file found:", api_found, "\n")
  
  utils_paths <- c("tests/contract/utils-schema.R", "utils-schema.R", "../contract/utils-schema.R")
  utils_found <- any(sapply(utils_paths, file.exists))
  cat("Utils file found:", utils_found, "\n")
  
  schema_paths <- c("tests/contract/schema", "schema", "../contract/schema")
  schema_found <- any(sapply(schema_paths, dir.exists))
  cat("Schema dir found:", schema_found, "\n")
  
  expect_true(api_found, "API file should be found in one of the expected paths")
  expect_true(utils_found, "Utils file should be found in one of the expected paths") 
  expect_true(schema_found, "Schema directory should be found in one of the expected paths")
})
