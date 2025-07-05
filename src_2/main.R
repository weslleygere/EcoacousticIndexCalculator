# main.R

# --- Bibliotecas ---
library(log4r)
library(future)
library(furrr)
library(tibble)

# --- Carregamento de fontes ---
source("src_2/LoggerUtils.R")
source("src_2/params_indices.R")
source("src_2/AudioProcessor.R")
source("src_2/IndexCalculator.R")
source("src_2/JobRunner.R")

# --- Criação dos loggers globais ---
Logger$new(logfile = "src_2/log/log_audio_load.txt",   level = "INFO", global_name = "logger_audio_load")
Logger$new(logfile = "src_2/log/log_index_calc.txt",   level = "INFO", global_name = "logger_index_calc")
Logger$new(logfile = "src_2/log/log_job_runner.txt",   level = "INFO", global_name = "logger_job")
# args <- commandArgs(trailingOnly = TRUE)

# if (length(args) < 1) {
#   stop("Uso: Rscript main.R <diretorio> [indice1 indice2 ...] [--range start end]")
# }

# # Verifica se há flag --range
# range_flag <- which(args == "--range")

# if (length(range_flag) == 1) {
#   pasta <- args[1]
#   indices <- if (range_flag > 2) args[2:(range_flag - 1)] else NULL

#   start_idx <- as.integer(args[range_flag + 1])
#   end_idx   <- as.integer(args[range_flag + 2])
# } else {
#   pasta <- args[1]
#   indices <- if (length(args) > 1) args[-1] else NULL
#   start_idx <- NULL
#   end_idx   <- NULL
# }

# --- Parâmetros manuais para teste interativo ---
pasta <- "data/20240923"
indices <- c("ACI")  # ou NULL para todos
start_idx <- 1
end_idx <- 2

# --- Coleta os arquivos .wav ---
arquivos <- list.files(pasta, pattern = "\\.wav$", full.names = TRUE)

if (length(arquivos) == 0) {
  stop("Nenhum arquivo .wav encontrado no diretório especificado.")
}

# --- Aplica intervalo, se fornecido ---
if (!is.null(start_idx) && !is.null(end_idx)) {
  if (start_idx < 1 || end_idx > length(arquivos) || start_idx > end_idx) {
    stop("Intervalo inválido: fora dos limites.")
  }
  arquivos <- arquivos[start_idx:end_idx]
}

# --- Executa o JobRunner ---
job <- JobRunner$new(files = arquivos, indices = indices)
resultado <- job$run()

# --- Salvar resultado em Parquet ---
output_dir <- "resultados"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Gera nome do arquivo com base na pasta e no intervalo (se houver)
base_nome <- basename(normalizePath(pasta))
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
intervalo <- if (!is.null(start_idx)) paste0("_", start_idx, "-", end_idx) else ""
arquivo_saida <- file.path(output_dir, paste0("indices_", base_nome, intervalo, "_", timestamp, ".parquet"))

arrow::write_parquet(resultado, arquivo_saida)
get("logger_job", envir = .GlobalEnv)$info(paste("Resultados salvos em:", arquivo_saida))