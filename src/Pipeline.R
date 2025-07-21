##' @title Pipeline
##' @description Orchestrates processing of acoustic indices with periodic checkpointing using Arrow datasets, argument parsing via optparse, and efficient logging.
##'
##' @section Fields:
##' \describe{
##'   \item{args}{Parsed command line options}
##'   \item{logger}{Main logger for the pipeline}
##'   \item{files}{Vector of WAV files to process}
##'   \item{indices}{Vector of indices to calculate}
##'   \item{start_idx}{Start index for file filtering}
##'   \item{end_idx}{End index for file filtering}
##'   \item{params}{List of parameters for index calculation (cached globally)}
##'   \item{batches}{List of file batches}
##'   \item{output_dir}{Output directory for checkpoints and final result}
##'   \item{directory}{Input directory for WAV files}
##' }
Pipeline <- R6::R6Class(
  "Pipeline",
  private = list(
    args        = NULL,
    logger      = NULL,
    files       = NULL,
    indices     = NULL,
    start_idx   = NULL,
    end_idx     = NULL,
    params      = NULL,
    batches     = NULL,
    output_dir  = "data/results",
    directory   = NULL,

    #' @description Parse command line arguments with optparse (simple and efficient)
    parse_args = function() {
      tryCatch({
        option_list <- list(
          optparse::make_option(c("-d","--directory"), type="character",
                                help="Input directory of WAV files", metavar="DIR"),
          optparse::make_option(c("-i","--indices"), type="character",
                                help="Comma-separated list of indices to calculate", metavar="IDX1,IDX2,..."),
          optparse::make_option(c("-r","--range"), type="character",
                                help="Start and end file indices as START,END", metavar="START,END")
        )
        parser <- optparse::OptionParser(option_list=option_list)
        opts <- optparse::parse_args(parser)

        private$args      <- opts
        private$directory <- opts$directory

        # Indices: comma-separated list or NULL
        if (!is.null(opts$indices) && nzchar(opts$indices)) {
          indices <- trimws(unlist(strsplit(opts$indices, ",")))
          if (any(indices == "")) stop()
          private$indices <- indices
        } else {
          private$indices <- NULL
        }

        # Range: comma-separated integers or NULL
        if (!is.null(opts$range) && nzchar(opts$range)) {
          parts <- trimws(unlist(strsplit(opts$range, ",")))
          nums <- suppressWarnings(as.integer(parts))
          if (!(length(nums) == 2 && all(!is.na(nums)))) stop()
          private$start_idx <- nums[1]
          private$end_idx   <- nums[2]
        } else {
          private$start_idx <- NULL
          private$end_idx   <- NULL
        }
      }, error = function(e) {
        stop("Invalid argument syntax. Use -i IDX1,IDX2,... (with commas) and -r START,END.")
      })
    },
    #' @description List WAV files and apply optional range filter
    prepare_files = function() {
      if (!dir.exists(private$directory)) {
        stop(paste0("Directory does not exist: ", private$directory))
      }
      private$files <- list.files(private$directory, pattern = "\\.wav$", full.names = TRUE)
      if (length(private$files) == 0) {
        stop("No .wav files found in specified directory.")
      }
      if (!is.null(private$start_idx) && !is.null(private$end_idx)) {
        if (private$start_idx < 1 || private$end_idx > length(private$files) ||
              private$start_idx > private$end_idx) {
          stop("Invalid range: out of bounds. START must be >= 1, END must be <= total files, and START <= END.")
        }
        private$files <- private$files[private$start_idx:private$end_idx]
      }
    },

    #' @description Load index parameters (cached globally) and set defaults, with validation
    load_params = function() {
      if (!exists(".INDEX_PARAMS", envir = .GlobalEnv)) {
        .GlobalEnv$.INDEX_PARAMS <- jsonlite::fromJSON(
          "indices_parameters/params.json",
          simplifyVector = TRUE
        )
      }
      private$params <- .GlobalEnv$.INDEX_PARAMS
      valid_indices <- names(private$params)
      if (is.null(private$indices)) {
        private$indices <- valid_indices
      } else {
        invalid <- setdiff(private$indices, valid_indices)
        if (length(invalid) > 0) {
          stop(paste0(
            "Invalid index name(s): ", paste(invalid, collapse = ", "),
            ". Please check and use only valid indices: ", paste(valid_indices, collapse = ", "), "."
          ))
        }
      }
    },

    #' @description Prepare file batches for parallel processing
    prepare_batches = function() {
      batch_size    <- future::availableCores() * 2
      private$batches <- split(
        private$files,
        ceiling(seq_along(private$files) / batch_size)
      )
      private$logger$info(
        glue::glue("⚙️ Batch size: {batch_size}; total batches: {length(private$batches)}")
      )
    },

    #' @description Process batches with purrr and checkpoint via Arrow
    process_batches = function() {
      purrr::imap(private$batches, function(files_batch, batch_idx) {
        private$logger$info(
          glue::glue("🚀 Processing batch {batch_idx}/{length(private$batches)}: {length(files_batch)} files")
        )
        result <- ParallelRunner$new(
          files = files_batch,
          indices = private$indices,
          params = private$params
        )$run()
        result$batch <- batch_idx
        arrow::write_dataset(
          result,
          path = private$output_dir,
          partitioning = "batch"
        )
        private$logger$info(
          glue::glue("💾 Checkpointed batch {batch_idx}")
        )
      })
    },

    #' @description Combine checkpoints and save final result
    combine_and_save = function() {
      ds       <- arrow::open_dataset(private$output_dir)
      combined <- dplyr::collect(ds)
      suffix   <- if (!is.null(private$start_idx)) (
        paste0("_", private$start_idx, "-", private$end_idx)
      ) else ""
      timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
      final_file <- file.path(
        private$output_dir,
        paste0(
          "indices_",
          basename(normalizePath(private$directory)),
          suffix,
          "_",
          timestamp,
          ".parquet"
        )
      )
      arrow::write_parquet(combined, final_file)
      # Cleanup temporary batch partitions if final result saved successfully
      temp_dirs  <- list.dirs(private$output_dir, recursive = FALSE, full.names = TRUE)
      batch_dirs <- temp_dirs[grepl("^batch=", basename(temp_dirs))]
      if (length(batch_dirs) > 0) {
        unlink(batch_dirs, recursive = TRUE, force = TRUE)
        private$logger$info(
          glue::glue("🧹 Removed temporary batch directories: {paste(basename(batch_dirs), collapse = ", ")}")
        )
      }
      private$logger$info(
        glue::glue("✅ Result saved to: {final_file}")
      )
    }
  ),

  public = list(
    #' @description Initialize the pipeline
    initialize = function(args = commandArgs(trailingOnly = TRUE)) {
      private$logger <- Logger$new(
        logfile = "data/log/log_main.txt",
        console = TRUE
      )
      private$parse_args()
      fs::dir_create(private$output_dir)
      private$prepare_files()
      private$load_params()
      private$prepare_batches()
    },

    #' @description Run the complete pipeline with concise logging
    run = function() {
      idxs <- if (is.null(private$indices)) (
        "ALL"
      ) else paste(private$indices, collapse = ", ")
      private$logger$info(
        glue::glue(
          "🎵 Starting pipeline on '{basename(private$directory)}' — {length(private$files)} files — indices: {idxs}"
        )
      )
      private$process_batches()
      private$combine_and_save()
    }
  )
)