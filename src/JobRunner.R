job_runner <- R6::R6Class("JobRunner",
  public = list(
    files = NULL,

    initialize = function(files) {
      self$files <- files
    },

    run = function() {
      future::plan(multisession)
      furrr::future_map_dfr(
        self$files,
        function(file) {
          start_time <- Sys.time()
          log_info(paste("Processando: ", basename(file)))

          proc <- audio_processor$new(file)
          if (!proc$is_valid()) return(NULL)

          calc <- index_calculator$new(proc$wav)
          result <- calc$compute_all()

          end_time <- Sys.time()
          duration_sec <- as.numeric(difftime(end_time, start_time, units = "secs"))

          result$file <- basename(file)
          result$proc_time_sec <- duration_sec
          return(result)
        },
        .progress = TRUE
      )
    }
  )
)
