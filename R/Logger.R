#' Logger: Wrapper for log4r with global registration
#'
#' This class wraps a `log4r` logger and registers it in the global environment.
#' It supports INFO, WARN, and ERROR levels, and automatically creates log directories if needed.
#'
#' @field logger Internal log4r logger object
#' @export
Logger <- R6::R6Class("Logger",
  private = list(
    logger = NULL
  ),

  public = list(

    #' @description Initialize a new Logger
    #'
    #' @param logfile Path to the log file (default: "log.txt")
    #' @param level Logging level (default: "INFO")
    #' @param global_name Name to assign the logger to in the global environment
    initialize = function(logfile = "log.txt", level = "INFO", global_name = "logger") {
      log_dir <- dirname(logfile)

      # Create directory if it doesn't exist
      if (!dir.exists(log_dir)) {
        dir.create(log_dir, recursive = TRUE)
      }

      # Create the logger and set configuration
      private$logger <- log4r::create.logger()
      log4r::logfile(private$logger) <- logfile
      log4r::level(private$logger) <- level

      # Assign logger object to global environment
      assign(global_name, self, envir = .GlobalEnv)
    },

    #' Generic logging method
    #'
    #' @param level Logging level: "info", "warn", or "error"
    #' @param msg Message string to log
    log = function(level, msg) {
      full_msg <- paste(Sys.time(), "|", msg)

      switch(level,
        info  = log4r::info(private$logger, full_msg),
        warn  = log4r::warn(private$logger, full_msg),
        error = log4r::error(private$logger, full_msg),
        stop("Invalid log level: use 'info', 'warn', or 'error'")
      )
    },

    #' Log an INFO message
    #'
    #' @param msg Message string to log
    info = function(msg) {
      self$log("info", msg)
    },

    #' Log a WARN message
    #'
    #' @param msg Message string to log
    warn = function(msg) {
      self$log("warn", msg)
    },

    #' Log an ERROR message
    #'
    #' @param msg Message string to log
    error = function(msg) {
      self$log("error", msg)
    }
  )
)    