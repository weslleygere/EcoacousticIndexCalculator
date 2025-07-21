#' AudioProcessor: WAV file loader and wrapper
#'
#' This class reads a WAV file from disk and logs errors for unsupported formats or read failures.
#' It returns a named list containing the file's basename and the wave object.
#'
#' @field filepath Path to the audio file (.wav)
#' @field wav Internal slot to store the wave object (tuneR::Wave)
#' @field logger Logger object (log4r-style) to report errors
AudioProcessor <- R6::R6Class("AudioProcessor",
  private = list(
    filepath = NULL,
    wav      = NULL,
    logger   = NULL
  ),

  public = list(
    #' Initialize AudioProcessor
    #'
    #' @param filepath Path to the WAV file
    #' @param logger Logger object for logging errors
    initialize = function(filepath, logger) {
      private$filepath <- filepath
      private$logger   <- logger
    },

    #' Read the audio file and return its contents
    #'
    #' @return A named list with:
    #'   \item{filename}{The basename of the file path}
    #'   \item{wav}{The wave object (or NULL if failed)}
    get_audio = function() {
      # 1) Check file extension
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

      # 2) Attempt to read WAV
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