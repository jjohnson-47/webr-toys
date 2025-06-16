library(testthat)
library(httr)
library(callr)

# Load test utilities
if (file.exists("tests/contract/utils-schema.R")) {
  source("tests/contract/utils-schema.R")
  source("tests/contract/test-helpers.R")
} else if (file.exists("utils-schema.R")) {
  source("utils-schema.R")
  source("test-helpers.R")
} else {
  stop("Cannot find test utility files")
}

# Contract tests for /ping endpoint
test_that("/ping response conforms to JSON schema", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to respond
  res <- wait_for_api(port, "/ping")
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Parse response body
  response_body <- jsonlite::fromJSON(rawToChar(res$content))
  
  # Contract validation - response must conform to schema
  schema_path <- get_schema_path("ping-response.json")
  expect_true(file.exists(schema_path), "Schema file must exist")
  
  # Validate response against JSON schema
  expect_true(
    validate_json_schema(response_body, schema_path),
    "Response must conform to ping-response.json schema"
  )
  
  # Additional contract assertions
  expect_equal(response_body$status, "pong", info = "Status must be 'pong'")
  expect_equal(length(names(response_body)), 1, info = "Response must have exactly one property")
})

test_that("ping schema validates correctly", {
  # Test valid response
  valid_response <- list(status = "pong")
  schema_path <- get_schema_path("ping-response.json")
  
  expect_true(validate_json_schema(valid_response, schema_path))
  
  # Test invalid responses
  invalid_responses <- list(
    list(status = "invalid"),  # Wrong enum value
    list(wrong_field = "pong"),  # Wrong field name
    list(status = "pong", extra = "field"),  # Additional properties
    list()  # Missing required field
  )
  
  for (invalid_resp in invalid_responses) {
    expect_error(
      validate_json_schema(invalid_resp, schema_path),
      class = "error"
    )
  }
})