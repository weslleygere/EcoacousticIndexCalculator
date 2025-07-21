#' @title Logger
#' @description Wrapper for log4r. Supports INFO, WARN, and ERROR levels, automatically creates log directories if needed, and can optionally log to the console.
#'
#' @section Fields:
#' \describe{
#'   \item{logger}{Internal log4r logger object}
#' }
Logger <- R6::R6Class(
  classname = "Logger",
  private = list(
    logger = NULL,

    #' @description Internal method: Log a message at a specific level
    #' @param level Logging level: "info", "warn", or "error"
    #' @param msg Message string to log
    log = function(level, msg) {
      full_msg <- paste(msg)
      tryCatch(
        {
          switch(level,
            info  = log4r::info(private$logger, full_msg),
            warn  = log4r::warn(private$logger, full_msg),
            error = log4r::error(private$logger, full_msg),
            stop("Invalid log level: use 'info', 'warn', or 'error'")
          )
        },
        error = function(e) {
          message("Failed to write log: ", e$message)
        }
      )
    }
  ),

  public = list(

    #' @description Initialize a new Logger object
    #' @param logfile Path to the log file (default: "log.txt")
    #' @param console Logical; if TRUE, also log messages to the console (default: FALSE)
    initialize = function(logfile = "log.txt",
                          console = FALSE) {
      log_dir <- dirname(logfile)
      if (!dir.exists(log_dir)) {
        dir.create(log_dir, recursive = TRUE)
      }

      private$logger <- log4r::create.logger(logfile = logfile, level = "INFO")

      if (console) {
        # Add console appender to the logger's appenders list
        private$logger$appenders <- list(
          log4r::file_appender(logfile),
          log4r::console_appender()
        )
      }
    },

    #' @description Log an INFO message
    #' @param msg Message string to log
    info = function(msg) {
      private$log("info", msg)
    },

    #' @description Log a WARN message
    #' @param msg Message string to log
    warn = function(msg) {
      private$log("warn", msg)
    },

    #' @description Log an ERROR message
    #' @param msg Message string to log
    error = function(msg) {
      private$log("error", msg)
    }
  )
)