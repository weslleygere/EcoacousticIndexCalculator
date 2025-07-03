# FFT e tempo
fft_w <- 512
ovlp  <- 0
j     <- 5

# Parâmetros para BIO
bio_min_freq <- 2000
bio_max_freq <- 8000

# Parâmetros para ADI e AEI
max_freq <- 22000
freq_step    <- 1000

log_info <- function(msg) {
  message(Sys.time(), " | ", msg)
  if (exists("logger", envir = .GlobalEnv)) {
    log4r::info(get("logger", envir = .GlobalEnv), msg)
  }
}