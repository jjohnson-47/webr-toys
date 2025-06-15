# Minimal Plumber API for the webr-toys MVP
# -----------------------------------------------------------------------------
# Emits a plain JSON `{"status": "pong"}` at /ping.
# Later this file will add auth middleware and hub event emission via hub_py.

#' Health-check endpoint
#'
#' @get /ping
function() {
  list(status = "pong")
}

