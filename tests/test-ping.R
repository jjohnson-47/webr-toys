library(testthat)
library(httr)
library(callr)

# boots the Plumber API in a background R process
test_that("/ping returns 200 and pong", {
  port <- httpuv::randomPort()

  # run API in background
  proc <- callr::r_bg(
    func = function(p) {
      pr <- plumber::plumb("api/plumber.R")
      pr$run(host = "127.0.0.1", port = p, swagger = FALSE)
    },
    args = list(port),
    supervise = TRUE
  )

  # wait (≤5 s) for server
  res <- NULL
  for (i in seq_len(10)) {
    Sys.sleep(0.5)
    res <- tryCatch(
      GET(sprintf("http://127.0.0.1:%d/ping", port)),
      error = function(e) NULL
    )
    if (!is.null(res)) break
  }

  proc$kill()  # teardown

  expect_false(is.null(res))
  expect_equal(status_code(res), 200)
  body <- jsonlite::fromJSON(rawToChar(res$content))
  expect_equal(body$status, "pong")
})
