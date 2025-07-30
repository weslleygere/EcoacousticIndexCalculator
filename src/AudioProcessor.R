#' @title AudioProcessor
#' @description WAV file loader and wrapper using R6. Reads a WAV file from disk and logs errors for unsupported formats or read failures. Returns a named list containing the file's basename and the wave object.
#'
#' @section Fields:
#' \describe{
#'   \item{filepath}{Path to the audio file (.wav)}
#'   \item{wav}{Internal slot to store the wave object (tuneR::Wave)}
#'   \item{logger}{Logger object (log4r-style) to report errors}
#' }
AudioProcessor <- R6::R6Class(
  classname = "AudioProcessor",
  private = list(
    filepath = NULL,
    wav      = NULL,
    logger   = NULL
  ),

  public = list(
    #' @description Initialize AudioProcessor object
    #' @param filepath Path to the WAV file
    #' @param logger Logger object for logging errors
    initialize = function(filepath, logger) {
      private$filepath <- filepath
      private$logger   <- logger
    },

    #' @description Read the audio file and return its contents
    #' @details Checks file extension and attempts to read the WAV file. Logs errors for unsupported formats or read failures.
    #' @return Named list with:
    #'   \item{filename}{The basename of the file path}
    #'   \item{wav}{The wave object (or NULL if failed)}
    get_audio = function() {
      ext <- tolower(tools::file_ext(private$filepath))
      if (ext != "wav") {
        private$logger$error(
          paste("Unsupported file extension for", private$filepath, "- skipping")
        )
        return(list(
          filename = basename(private$filepath),
          wav      = NULL
        ))
      }

      private$wav <- tryCatch(
        tuneR::readWave(private$filepath),
        error = function(e) {
          private$logger$error(
            paste("Failed to read", private$filepath, "->", e$message)
          )
          NULL
        }
      )

      return(list(
        filename = basename(private$filepath),
        wav      = private$wav
      ))
    }
  )
)
