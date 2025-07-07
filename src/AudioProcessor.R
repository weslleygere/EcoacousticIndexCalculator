#' AudioProcessor: WAV file loader and wrapper
#'
#' This class reads a WAV file from disk and optionally logs errors if reading fails.
#' It returns a named list containing the original file path and the wave object.
#'
#' @field filepath Path to the audio file (.wav)
#' @field wav Internal slot to store the wave object (tuneR::Wave)
#' @field logger Optional logger object (log4r-style) to report errors
#' @export
AudioProcessor <- R6::R6Class("AudioProcessor",
  private = list(
    filepath = NULL,
    wav = NULL,
    logger = NULL
  ),

  public = list(

    #' @description Initialize AudioProcessor
    #'
    #' @param filepath Path to the WAV file
    #' @param logger Optional logger object for logging errors
    initialize = function(filepath, logger = NULL) {
      private$filepath <- filepath
      private$logger <- logger
    },

    #' Read the audio file and return its contents
    #'
    #' @return A named list with:
    #'   \item{filename}{The original file path}
    #'   \item{wav}{The wave object (or NULL if failed)}
    get_audio = function() {
      private$wav <- tryCatch(
        tuneR::readWave(private$filepath),
        error = function(e) {
          private$logger$error(paste("Failed to read", private$filepath, "->", e$message))
          NULL
        }
      )

      return(list(
        filename = private$filepath,
        wav = private$wav
      ))
    }
  )
)
