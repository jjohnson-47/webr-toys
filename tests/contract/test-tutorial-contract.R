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

# Contract tests for tutorial endpoints
test_that("/tutorial/info response conforms to schema", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/tutorial/info", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Parse response body (prevent auto-conversion to data.frame for arrays)
  response_body <- jsonlite::fromJSON(rawToChar(res$content), simplifyDataFrame = FALSE)
  
  # Contract validation
  schema_path <- if (file.exists("tests/contract/schema/tutorial-info-response.json")) {
    "tests/contract/schema/tutorial-info-response.json"
  } else if (file.exists("schema/tutorial-info-response.json")) {
    "schema/tutorial-info-response.json"
  } else {
    stop("Cannot find tutorial-info-response.json schema file")
  }
  expect_true(file.exists(schema_path), "Schema file must exist")
  
  # Validate response against JSON schema
  expect_true(
    validate_json_schema(response_body, schema_path),
    "Response must conform to tutorial-info-response.json schema"
  )
  
  # Additional contract assertions
  expect_equal(response_body$course, "STAT A253 - University of Alaska Anchorage")
  expect_equal(response_body$distribution$name, "Triangular Distribution")
  expect_length(response_body$examples, 3)
})

test_that("/tutorial/calculate-probability response conforms to schema", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/tutorial/calculate-probability?lower=8&upper=11", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Parse response body (prevent auto-conversion to data.frame for arrays)
  response_body <- jsonlite::fromJSON(rawToChar(res$content), simplifyDataFrame = FALSE)
  
  # Contract validation
  schema_path <- if (file.exists("tests/contract/schema/probability-response.json")) {
    "tests/contract/schema/probability-response.json"
  } else if (file.exists("schema/probability-response.json")) {
    "schema/probability-response.json"
  } else {
    stop("Cannot find probability-response.json schema file")
  }
  expect_true(file.exists(schema_path), "Schema file must exist")
  
  # Validate response against JSON schema
  expect_true(
    validate_json_schema(response_body, schema_path),
    "Response must conform to probability-response.json schema"
  )
  
  # Additional contract assertions
  expect_equal(response_body$lower_bound, 8)
  expect_equal(response_body$upper_bound, 11)
  expect_true(response_body$probability >= 0 && response_body$probability <= 1)
  expect_true(grepl("P\\(8.00 < X < 11.00\\)", response_body$interpretation))
})

test_that("/tutorial/pdf-plot returns PNG image", {
  port <- httpuv::randomPort()
  
  # Start API in background using helper
  proc <- start_test_api(port)
  
  # Wait for server to start (use proper helper)
  res <- wait_for_api(port, "/tutorial/pdf-plot", max_attempts = 20)
  
  proc$kill()  # Clean up
  
  # Basic response validation
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  
  # Check content type is PNG
  expect_equal(headers(res)$`content-type`, "image/png")
  
  # Check response has binary content
  expect_true(length(res$content) > 1000)  # PNG should be substantial size
})