library(testthat)

test_that("basic functionality works", {
  expect_equal(2 + 2, 4)
  expect_true(file.exists("api/plumber.R"))
  expect_true(file.exists("tests/contract/utils-schema.R"))
})

test_that("R packages are available", {
  expect_true(requireNamespace("plumber", quietly = TRUE))
  expect_true(requireNamespace("jsonlite", quietly = TRUE))
  expect_true(requireNamespace("testthat", quietly = TRUE))
})
