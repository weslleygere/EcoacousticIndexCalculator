args <- commandArgs(trailingOnly = TRUE)
start_idx <- as.integer(args[1])
end_idx   <- as.integer(args[2])

if (is.na(start_idx) || is.na(end_idx) || start_idx < 1 || end_idx < start_idx) {
  stop("Uso: Rscript main.R <start> <end>")
}

source("R/globals.R")
source("R/AudioProcessor.R")
source("R/IndexCalculator.R")
source("R/JobRunner.R")

library(tuneR)
library(seewave)
library(soundecology)
library(R6)
library(furrr)
library(future)
library(tibble)
library(magrittr)
library(purrr)
library(arrow)
library(log4r)

# Criar logger para o lote atual
logfile <- sprintf("logs/lote_%05d_%05d.log", start_idx, end_idx)
dir.create("logs", showWarnings = FALSE)
logger <- log4r::logger(threshold = "INFO", appenders = file_appender(logfile))

file_list <- list.files("caminho/para/wavs", full.names = TRUE, pattern = "\\.wav$")
files_subset <- file_list[start_idx:end_idx]

runner <- job_runner$new(files_subset)
resultados <- runner$run()

output_file <- sprintf("resultados_%05d_%05d.parquet", start_idx, end_idx)
arrow::write_parquet(resultados, output_file)
message(Sys.time(), " | Lote salvo em: ", output_file)
