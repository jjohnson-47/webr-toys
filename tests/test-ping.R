if (!requireNamespace("httr", quietly = TRUE)) {
  install.packages("httr", repos = "https://cloud.r-project.org")
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  install.packages("jsonlite", repos = "https://cloud.r-project.org")
}

library(testthat)
library(httr)

# Assumes the API is already running on localhost:8000, e.g. via docker-compose

test_that("/ping returns 200 and pong", {
  res <- tryCatch(
    GET("http://localhost:8000/ping"),
    error = function(e) NULL
  )
  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  body <- jsonlite::fromJSON(rawToChar(res$content))
  expect_equal(body$status, "pong")
})

