# Interactive R Tutorial: Continuous Probability Distributions
# -----------------------------------------------------------------------------
# Educational endpoints for STAT A253 - Continuous PDFs tutorial
# Provides interactive R-powered tools for learning probability distributions

# Null coalescing operator helper
`%||%` <- function(a, b) if (is.null(a)) b else a

# Triangular PDF function from the tutorial
triangular_pdf <- function(x) {
  ifelse(x >= 5 & x < 10, 0.04 * (x - 5),
         ifelse(x >= 10 & x <= 15, -0.04 * (x - 15), 0))
}

#' Generate triangular PDF plot
#' 
#' @get /tutorial/pdf-plot
#' @param lower:numeric Lower bound for shading (optional)
#' @param upper:numeric Upper bound for shading (optional)
#' @serializer png
function(lower = NULL, upper = NULL) {
  hub_log("Generating triangular PDF plot")
  
  # Create data for plotting
  x_values <- seq(4, 16, by = 0.1)
  pdf_values <- sapply(x_values, triangular_pdf)
  
  # Base plot
  p <- ggplot() +
    geom_line(aes(x = x_values, y = pdf_values), color = "blue", size = 1.2) +
    geom_hline(yintercept = 0, color = "black", linetype = "solid") +
    labs(
      title = "Triangular Probability Density Function",
      subtitle = "f(x) for Photocopier Friction Model",
      x = "x (friction coefficient)",
      y = "f(x) (probability density)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 12)
    ) +
    xlim(4, 16) +
    ylim(0, 0.21)
  
  # Add shading if bounds provided
  if (!is.null(lower) && !is.null(upper)) {
    # Create shading data
    shade_x <- seq(max(lower, 5), min(upper, 15), by = 0.01)
    shade_y <- sapply(shade_x, triangular_pdf)
    
    p <- p +
      geom_ribbon(aes(x = shade_x, ymin = 0, ymax = shade_y), 
                  fill = "lightblue", alpha = 0.7) +
      labs(subtitle = sprintf("Shaded area: P(%.1f < X < %.1f)", lower, upper))
  }
  
  hub_log(sprintf("Plot generated with bounds: [%s, %s]", lower %||% "none", upper %||% "none"))
  print(p)
}

#' Calculate probability for triangular distribution
#' 
#' @get /tutorial/calculate-probability
#' @param lower:numeric Lower bound for integration
#' @param upper:numeric Upper bound for integration
function(req, res, lower, upper) {
  hub_log(sprintf("Calculating P(%.2f < X < %.2f)", lower, upper))
  
  # Validate inputs
  if (is.null(lower) || is.null(upper)) {
    res$status <- 400
    return(list(error = "Both lower and upper bounds are required"))
  }
  
  if (lower >= upper) {
    res$status <- 400
    return(list(error = "Lower bound must be less than upper bound"))
  }
  
  # Calculate probability using integration
  result <- integrate(triangular_pdf, lower = lower, upper = upper)
  probability <- result$value
  
  hub_log(sprintf("Calculated probability: %.4f", probability))
  
  list(
    lower_bound = lower,
    upper_bound = upper,
    probability = round(probability, 6),
    interpretation = sprintf("P(%.2f < X < %.2f) = %.4f", lower, upper, probability),
    area_under_curve = probability,
    integration_error = result$abs.error
  )
}

#' Get tutorial information and examples
#' 
#' @get /tutorial/info
function() {
  hub_log("Serving tutorial information")
  
  list(
    title = "Interactive R Tutorial: Continuous Probability Distributions",
    course = "STAT A253 - University of Alaska Anchorage",
    topic = "5.1: Continuous Probability Distributions",
    distribution = list(
      name = "Triangular Distribution",
      formula = "f(x) = 0.04(x-5) for 5≤x<10; -0.04(x-15) for 10≤x≤15; 0 otherwise",
      domain = c(5, 15),
      mode = 10,
      interpretation = "Photocopier friction coefficient model"
    ),
    examples = list(
      list(
        question = "P(X < 10)",
        lower = 5,
        upper = 10,
        answer = 0.5
      ),
      list(
        question = "P(X > 12)", 
        lower = 12,
        upper = 15,
        answer = 0.18
      ),
      list(
        question = "P(8 < X < 11)",
        lower = 8,
        upper = 11,
        answer = 0.38
      )
    ),
    endpoints = list(
      "/tutorial/info" = "Get tutorial information",
      "/tutorial/pdf-plot" = "Generate PDF plot (optional: ?lower=8&upper=11 for shading)",
      "/tutorial/calculate-probability" = "Calculate probability (?lower=8&upper=11)"
    )
  )
}