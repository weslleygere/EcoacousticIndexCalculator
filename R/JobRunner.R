#' JobRunner: Parallel audio index computation
#'
#' This class handles the parallel execution of audio index extraction for a list of WAV files.
#' It uses the `future` and `furrr` packages to run index computations in multiple processes.
#'
#' @field files A character vector of file paths to be processed.
#' @field indices A character vector of index names to compute. If NULL, all indices will be calculated.
#' @export
JobRunner <- R6::R6Class("JobRunner",
  private = list(
    files = NULL,
    indices = NULL
  ),

  public = list(

    #' @description Initialize JobRunner
    #' @param files Character vector of file paths to be processed
    #' @param indices Character vector of indices to be computed (optional)
    initialize = function(files, indices = NULL) {
      private$files <- files
      private$indices <- indices
    },

    #' Run the parallel index computation
    #' @return A data frame (tibble) with computed indices and metadata for each audio file
    run = function() {
      # Ensure required symbols are available in each parallel worker
      AudioProcessor <- IndexCalculator::AudioProcessor
      IndexCalculator <- IndexCalculator::IndexCalculator
      Logger <- IndexCalculator::Logger
      # params_indices <- IndexCalculator::params_indices

      future::plan(future::multisession)

      Logger$new(logfile = "log/log_audio_load.txt",   level = "INFO", global_name = "logger_audio_load")
      Logger$new(logfile = "log/log_index_calc.txt",   level = "INFO", global_name = "logger_index_calc")
      Logger$new(logfile = "log/log_job_runner.txt",   level = "INFO", global_name = "logger_job")

      logger_job <- get("logger_job", envir = .GlobalEnv)
      logger_audio_load <- get("logger_audio_load", envir = .GlobalEnv)
      logger_index_calc <- get("logger_index_calc", envir = .GlobalEnv)

      logger_job$info("Starting parallel processing of audio files.")

      start_global <- Sys.time()

      results <- furrr::future_map_dfr(
        private$files,
        function(file_path) {
          source("indices_parameters/params.R")

          start_time <- Sys.time()

          audio_proc <- AudioProcessor$new(
            file_path,
            logger = logger_audio_load
          )

          wav_obj <- audio_proc$get_audio()

          if (is.null(wav_obj$wav)) {
            logger_job$warn(paste("Invalid audio file, skipping:", basename(file_path)))
            return(NULL)
          }

          index_calc <- IndexCalculator$new(
            filename = wav_obj$filename,
            wav = wav_obj$wav,
            logger = logger_index_calc
          )

          result <- index_calc$compute_indices(indices = private$indices)

          if (any(purrr::map_lgl(result, ~ all(is.na(.x))))) {
            logger_job$warn(paste("Index computation failed for:", basename(file_path)))
          }

          end_time <- Sys.time()

          result$start_processing_time <- start_time
          result$total_processing_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

          return(result)
        },
        .progress = TRUE
      )

      end_global <- Sys.time()

      total_time <- round(as.numeric(difftime(end_global, start_global, units = "secs")), 2)

      logger_job$info(paste("All audio files processed. Total time:", total_time, "seconds."))

      return(results)
    }
  )
)