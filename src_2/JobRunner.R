JobRunner <- R6::R6Class("JobRunner",
  private = list(
    files = NULL,
    indices = NULL
  ),

  public = list(

    initialize = function(files, indices = NULL) {
      private$files <- files
      private$indices <- indices
    },

    run = function() {
      future::plan(future::multisession)

      # Captura os loggers do ambiente global
      logger_job <- get("logger_job", envir = .GlobalEnv)
      logger_audio_load <- get("logger_audio_load", envir = .GlobalEnv)
      logger_index_calc <- get("logger_index_calc", envir = .GlobalEnv)

      furrr::future_map_dfr(
        private$files,
        function(file_path) {
          source("src_2/params_indices.R")
          start_time <- Sys.time()
          logger_job$info(paste("Iniciando processamento de:", basename(file_path)))

          proc <- AudioProcessor$new(file_path, logger = logger_audio_load)
          wav_obj <- proc$get_audio()

          if (is.null(wav_obj$wav)) {
            logger_job$warn(paste("Áudio inválido, pulando:", basename(file_path)))
            return(NULL)
          }

          # Passa o logger para IndexCalculator
          calc <- IndexCalculator$new(
            filename = wav_obj$filename,
            wav = wav_obj$wav,
            logger = logger_index_calc
          )

          result <- calc$compute_indices(indices = private$indices)

          if (is.null(result)) {
            logger_job$warn(paste("Falha no cálculo de índices para:", basename(file_path)))
            return(NULL)
          }

          end_time <- Sys.time()
          result$total_processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

          logger_job$info(
            paste("Finalizado:", basename(file_path),
                  "| Tempo:", round(result$total_processing_time, 2), "s")
          )

          return(result)
        },
        .progress = TRUE
      )
    }
  )
)