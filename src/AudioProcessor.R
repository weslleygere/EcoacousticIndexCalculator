audio_processor <- R6::R6Class("AudioProcessor",
  public = list(
    filepath = NULL,
    wav = NULL,

    initialize = function(filepath) {
      self$filepath <- filepath
      message(Sys.time(), " | Lendo arquivo: ", filepath)
      self$wav <- tryCatch(
        tuneR::readWave(filepath),
        error = function(e) {
          message(Sys.time(), " | ERRO ao ler ", filepath, ": ", e$message)
          return(NULL)
        }
      )
    },

    is_valid = function() {
      !is.null(self$wav)
    }
  )
)