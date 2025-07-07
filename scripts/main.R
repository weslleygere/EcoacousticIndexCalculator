# ============================================================
# main.R — Entry point for batch ecoacoustic index processing
#
# Usage:
#   Rscript main.R <directory> [index1 index2 ...] [--range start end]
#
# Description:
#   - Loads .wav files from a specified folder
#   - Optionally filters by index names and file range
#   - Runs JobRunner to compute acoustic indices in parallel
#   - Saves output as a timestamped Parquet file
# ============================================================

# ==== 1. Load package ====
library(IndexCalculator)

# ==== 2. Define main runner function ====
run_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) < 1) {
    stop("Usage: Rscript main.R <directory> [index1 index2 ...] [--range start end]")
  }

  # ==== 3. Parse input arguments ====
  range_flag <- which(args == "--range")

  if (length(range_flag) == 1) {
    directory <- args[1]
    indices <- if (range_flag > 2) args[2:(range_flag - 1)] else NULL

    start_idx <- as.integer(args[range_flag + 1])
    end_idx   <- as.integer(args[range_flag + 2])
  } else {
    directory <- args[1]
    indices <- if (length(args) > 1) args[-1] else NULL
    start_idx <- NULL
    end_idx   <- NULL
  }

  # ==== 4. List WAV files ====
  files <- list.files(directory, pattern = "\\.wav$", full.names = TRUE)

  if (length(files) == 0) {
    stop("No .wav files found in the specified directory.")
  }

  # ==== 5. Apply range filter if provided ====
  if (!is.null(start_idx) && !is.null(end_idx)) {
    if (start_idx < 1 || end_idx > length(files) || start_idx > end_idx) {
      stop("Invalid range: out of bounds.")
    }
    files <- files[start_idx:end_idx]
  }

  # ==== 6. Run JobRunner ====
  job <- JobRunner$new(files = files, indices = indices)
  result <- job$run()

  # ==== 7. Save results ====
  output_dir <- "results"
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  base_name <- basename(normalizePath(directory))
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  range_suffix <- if (!is.null(start_idx)) paste0("_", start_idx, "-", end_idx) else ""
  output_file <- file.path(output_dir, paste0("indices_", base_name, range_suffix, "_", timestamp, ".parquet"))

  arrow::write_parquet(result, output_file)

  get("logger_job", envir = .GlobalEnv)$info(paste("Results saved to:", output_file))
}

# ==== 8. Execute main ====
run_main()