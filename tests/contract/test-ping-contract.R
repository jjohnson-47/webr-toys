library(testthat)
library(httr)
library(callr)

# Load schema validation utilities
source("tests/contract/utils-schema.R")

# Contract tests for /ping endpoint
test_that("/ping response conforms to JSON schema", {
  port <- httpuv::randomPort()
  
  # Start API in background
  proc <- callr::r_bg(
    func = function(p) {
      pr <- plumber::plumb("api/plumber.R")
      pr$run(host = "127.0.0.1", port = p, swagger = FALSE)
    },
    args = list(port),
    supervise = TRUE
  )
  
  # Wait for server to start
  res <- NULL
  for (i in seq_len(10)) {
    Sys.sleep(0.5)
    res <- tryCatch(
      GET(sprintf("http://127.0.0.1:%d/ping", port)),
      error = function(e) NULL
    )
    if (!is.null(res)) break
  }
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Parse response body
  response_body <- jsonlite::fromJSON(rawToChar(res$content))
  
  # Contract validation - response must conform to schema
  schema_path <- "tests/contract/schema/ping-response.json"
  expect_true(file.exists(schema_path), "Schema file must exist")
  
  # Validate response against JSON schema
  expect_true(
    validate_json_schema(response_body, schema_path),
    "Response must conform to ping-response.json schema"
  )
  
  # Additional contract assertions
  expect_equal(response_body$status, "pong", "Status must be 'pong'")
  expect_equal(length(names(response_body)), 1, "Response must have exactly one property")
})

test_that("ping schema validates correctly", {
  # Test valid response
  valid_response <- list(status = "pong")
  schema_path <- "tests/contract/schema/ping-response.json"
  
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