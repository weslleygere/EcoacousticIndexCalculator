AudioProcessor <- R6::R6Class("AudioProcessor",
  private = list(
    filepath = NULL,
    wav = NULL,
    logger = NULL
  ),

  public = list(
    initialize = function(filepath, logger = NULL) {
      private$filepath <- filepath
      private$logger <- logger
    },

    get_audio = function() {
      private$wav <- tryCatch(
        tuneR::readWave(private$filepath),
        error = function(e) {
          if (!is.null(private$logger)) {
            private$logger$error(
              paste("Falha ao ler", private$filepath, "->", e$message)
            )
          }
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