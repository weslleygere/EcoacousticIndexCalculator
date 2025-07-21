# main.R — Entry point for batch ecoacoustic index processing
#
# Usage:
#   Rscript main.R <directory> [index1 index2 ...] [--range start end]
#
# Description:
#   - Loads .wav files from a specified folder
#   - Optionally filters by index names and file range
#   - Reads index parameters from JSON
#   - Runs JobRunner to compute acoustic indices in parallel
#   - Saves intermediate Parquet batches and consolidates into a final Parquet file

# ==== 1. Load sources ====
source("src/Logger.R")
source("src/AudioProcessor.R")
source("src/IndexCalculator.R")
source("src/JobRunner.R")

# ==== 2. Define main runner function ====
run_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) < 1) {
    stop("Usage: Rscript main.R <directory> [index1 index2 ...] [--range start end]")
  }

  # ==== 3. Parse input arguments ====
  range_flag <- which(args == "--range")
  if (length(range_flag) == 1) {
    directory <- args[1]
    indices   <- if (range_flag > 2) args[2:(range_flag - 1)] else NULL
    if (length(args) < (range_flag + 2)) stop("Please provide both start and end after '--range'.")
    start_idx <- as.integer(args[range_flag + 1])
    end_idx   <- as.integer(args[range_flag + 2])
  } else {
    directory <- args[1]
    indices   <- if (length(args) > 1) args[-1] else NULL
    start_idx <- NULL
    end_idx   <- NULL
  }

  # ==== 4. List WAV files ====
  files <- list.files(directory, pattern = "\\.wav$", full.names = TRUE)
  if (length(files) == 0) stop("No .wav files found in the specified directory.")

  # ==== 5. Apply range filter if provided ====
  if (!is.null(start_idx) && !is.null(end_idx)) {
    if (start_idx < 1 || end_idx > length(files) || start_idx > end_idx) stop("Invalid range: out of bounds.")
    files <- files[start_idx:end_idx]
  }

  # ==== 6. Load parameters JSON ====
  params <- jsonlite::fromJSON("indices_parameters/params.json", simplifyVector = TRUE)

  # ==== 7. Setup logging ====
  # Enable console output and file logging
  logger_main <- Logger$new(logfile = "data/log/log_main.txt", console = TRUE)

  logger_main$info("🎵 Starting acoustic index calculation")
  logger_main$info(glue::glue("📁 Directory: {directory}"))
  logger_main$info(glue::glue("🔢 Total files: {length(files)}"))
  logger_main$info(glue::glue("📊 Indices: {ifelse(is.null(indices), 'ALL', paste(indices, collapse=', '))}"))

  # ==== 8. Prepare batch directory ====
  output_dir <- "data/results"
  batch_dir  <- file.path(output_dir, "temp_batches")
  dir.create(batch_dir, recursive = TRUE, showWarnings = FALSE)

  # ==== 9. Divide files into batches ====
  batch_size  <- future::availableCores()
  batches     <- split(files, ceiling(seq_along(files) / batch_size))
  logger_main$info(glue::glue("⚙️ Batch size (cores): {batch_size}; total batches: {length(batches)}"))

  batch_paths <- character(length(batches))

  # ==== 10. Process each batch and save intermediate results ====
  for (i in seq_along(batches)) {
    n_files <- length(batches[[i]])
    logger_main$info(glue::glue("🚀 Processing batch {i}/{length(batches)} with {n_files} file(s)"))

    job    <- JobRunner$new(files = batches[[i]], indices = indices, params = params)
    result <- job$run()

    batch_file     <- file.path(batch_dir, paste0("batch_", i, ".parquet"))
    arrow::write_parquet(result, batch_file)
    batch_paths[i] <- batch_file

    logger_main$info(glue::glue("💾 Saved intermediate batch {i} to: {batch_file}"))
  }

  # ==== 11. Combine intermediate batches and write final output ====
  logger_main$info("📦 Combining intermediate batches into final result...")
  combined <- purrr::map_dfr(batch_paths, arrow::read_parquet)

  range_suffix <- if (!is.null(start_idx)) paste0("_", start_idx, "-", end_idx) else ""
  timestamp    <- format(Sys.time(), "%Y%m%d_%H%M%S")
  final_file   <- file.path(
    output_dir,
    paste0("indices_", basename(normalizePath(directory)), range_suffix, "_", timestamp, ".parquet")
  )

  arrow::write_parquet(combined, final_file)
  logger_main$info(glue::glue("✅ Final result saved to: {final_file}"))

  # ==== 12. Cleanup temporary batches ====
  unlink(batch_dir, recursive = TRUE)
}

# ==== 13. Execute main ====
run_main()