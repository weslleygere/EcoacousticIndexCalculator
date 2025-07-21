#' @title ParallelRunner
#' @description Parallel audio index computation for a list of WAV files. Uses future and furrr for parallelization and progress bar. Handles logging and reproducibility.
#'
#' @section Fields:
#' \describe{
#'   \item{files}{A character vector of file paths to be processed.}
#'   \item{indices}{A character vector of index names to compute. If NULL, all indices will be calculated.}
#'   \item{params}{A list of parameters for index computation.}
#'   \item{logger_job}{Logger for job-level messages.}
#'   \item{logger_audio_load}{Logger for audio loading messages.}
#'   \item{logger_index_calc}{Logger for index calculation messages.}
#'   \item{seed}{Optional integer seed for reproducible execution.}
#' }
ParallelRunner <- R6::R6Class(
  classname = "ParallelRunner",
  private = list(
    files             = NULL,
    indices           = NULL,
    params            = NULL,
    seed              = NULL,
    logger_job        = NULL,
    logger_audio_load = NULL,
    logger_index_calc = NULL,

    validate_files = function() {
      if (!is.character(private$files) || length(private$files) == 0) {
        stop("'files' must be a non-empty character vector of file paths.")
      }
      missing <- private$files[!file.exists(private$files)]
      if (length(missing) > 0) {
        private$logger_job$warn(
          paste("The following files were not found and will be skipped:",
                paste(missing, collapse = ", "))
        )
        private$files <- private$files[file.exists(private$files)]
      }
    }
  ),

  public = list(
    #' @description Initialize ParallelRunner object
    #' @param files Character vector of file paths to be processed
    #' @param indices Character vector of indices to be computed (optional)
    #' @param params List of parameters for index computation
    #' @param log_dir Directory where log files will be created (default: "data/log")
    #' @param seed Optional integer seed for reproducible execution
    initialize = function(files,
                          indices = NULL,
                          params,
                          log_dir = "data/log",
                          seed = 42) {
      private$files   <- files
      private$indices <- indices
      private$params  <- params
      private$seed    <- seed

      if (!dir.exists(log_dir)) dir.create(log_dir, recursive = TRUE)

      private$logger_job        <- Logger$new(logfile = file.path(log_dir, "log_job_runner.txt"))
      private$logger_audio_load <- Logger$new(logfile = file.path(log_dir, "log_audio_load.txt"))
      private$logger_index_calc <- Logger$new(logfile = file.path(log_dir, "log_index_calc.txt"))

      private$validate_files()
    },

    #' @description Run the parallel index computation
    #' @return Tibble with results and processing metadata for each audio file
    run = function() {
      future::plan(future::multisession)
      private$logger_job$info("Starting parallel processing of audio files.")
      start_global <- Sys.time()

      if (length(private$files) == 0) {
        private$logger_job$warn("No valid files to process; exiting run().")
        return(tibble::tibble(
          filename = character(),
          status   = character(),
          total_processing_time_sec = numeric()
        ))
      }

      results <- furrr::future_map_dfr(
        private$files,
        function(file_path) {
          tryCatch({
            start_time <- Sys.time()

            audio_proc <- AudioProcessor$new(file_path, logger = private$logger_audio_load)
            wav_obj <- audio_proc$get_audio()

            if (is.null(wav_obj$wav)) {
              private$logger_job$warn(paste("Invalid audio file, skipping:", basename(file_path)))
              return(tibble::tibble(
                filename = basename(file_path),
                status   = "bad_wav",
                total_processing_time_sec = NA_real_
              ))
            }

            index_calc <- IndexCalculator$new(
              filename = wav_obj$filename,
              wav      = wav_obj$wav,
              params   = private$params,
              logger   = private$logger_index_calc
            )

            result <- if (is.null(private$indices)) {
              index_calc$compute_indices()
            } else {
              index_calc$compute_indices(indices = private$indices)
            }
            end_time <- Sys.time()
            elapsed <- round(as.numeric(difftime(end_time, start_time, units = "secs")), 2)

            result$status <- "ok"
            result$total_processing_time_sec <- elapsed

            result

          }, error = function(e) {
            private$logger_job$error(paste("Error processing", basename(file_path), ":", e$message))
            tibble::tibble(
              filename = basename(file_path),
              status   = "error",
              total_processing_time_sec = NA_real_,
              error_message = e$message
            )
          })
        },
        .options = furrr::furrr_options(seed = private$seed),
        .progress = TRUE
      )

      cat("\n")

      end_global <- Sys.time()
      total_time <- round(as.numeric(difftime(end_global, start_global, units = "secs")), 2)
      private$logger_job$info(paste("All audio files processed. Total time:", total_time, "seconds."))

      results
    }
  )
)