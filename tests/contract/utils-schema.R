# JSON Schema Validation Utilities for Contract Tests
# -----------------------------------------------------------------------------
# Provides helper functions for validating API responses against JSON schemas

library(jsonlite)

#' Validate JSON response against schema
#' 
#' @param response_json JSON string or R object to validate
#' @param schema_path Path to JSON schema file
#' @return TRUE if valid, throws error with details if invalid
validate_json_schema <- function(response_json, schema_path) {
  # Convert R object to JSON if needed
  if (!is.character(response_json)) {
    response_json <- jsonlite::toJSON(response_json, auto_unbox = TRUE)
  }
  
  # Parse JSON response
  response_data <- jsonlite::fromJSON(response_json)
  
  # Load schema
  schema <- jsonlite::fromJSON(schema_path)
  
  # Basic validation (simplified - could use jsonvalidate package for full JSON Schema support)
  validate_object_against_schema(response_data, schema)
  
  return(TRUE)
}

#' Basic schema validation (simplified implementation)
#' 
#' @param data R object to validate
#' @param schema Schema definition
validate_object_against_schema <- function(data, schema) {
  # Check required properties
  if (!is.null(schema$required)) {
    for (prop in schema$required) {
      if (!prop %in% names(data)) {
        stop(sprintf("Missing required property: %s", prop))
      }
    }
  }
  
  # Check properties
  if (!is.null(schema$properties)) {
    for (prop_name in names(schema$properties)) {
      if (prop_name %in% names(data)) {
        prop_schema <- schema$properties[[prop_name]]
        prop_value <- data[[prop_name]]
        
        # Type validation
        if (!is.null(prop_schema$type)) {
          validate_type(prop_value, prop_schema$type, prop_name)
        }
        
        # Enum validation
        if (!is.null(prop_schema$enum)) {
          if (!prop_value %in% prop_schema$enum) {
            stop(sprintf("Property %s value '%s' not in allowed enum values: %s", 
                        prop_name, prop_value, paste(prop_schema$enum, collapse=", ")))
          }
        }
      }
    }
  }
  
  # Check for additional properties if not allowed
  if (!is.null(schema$additionalProperties) && !schema$additionalProperties) {
    allowed_props <- names(schema$properties)
    actual_props <- names(data)
    extra_props <- setdiff(actual_props, allowed_props)
    if (length(extra_props) > 0) {
      stop(sprintf("Additional properties not allowed: %s", paste(extra_props, collapse=", ")))
    }
  }
}

#' Validate data type
#' 
#' @param value Value to check
#' @param expected_type Expected JSON Schema type
#' @param prop_name Property name for error messages
validate_type <- function(value, expected_type, prop_name) {
  actual_type <- switch(class(value)[1],
    "character" = "string",
    "numeric" = "number",
    "integer" = "integer", 
    "logical" = "boolean",
    "list" = "object",
    "array" = "array",
    "unknown"
  )
  
  if (actual_type != expected_type) {
    stop(sprintf("Property %s expected type %s but got %s", prop_name, expected_type, actual_type))
  }
}