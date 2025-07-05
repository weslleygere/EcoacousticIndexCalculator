IndexCalculator <- R6::R6Class("IndexCalculator",
  private = list(
    filename = NULL,
    wav = NULL,
    logger = NULL,
    all_indices = c(
      "ACI", "NDSI", "BIO", "ADI", "AEI",
      "ENTROPY", "TEMP_ENT", "SPEC_ENT", "MAE", "NP"
    )
  ),

  public = list(

    initialize = function(filename, wav, logger = NULL) {
      private$filename <- filename
      private$wav <- wav
      private$logger <- logger
    },

    medir_tempo = function(func, nome_indice) {
      inicio <- Sys.time()
      resultado <- func()
      fim <- Sys.time()
      tempo_segundos <- as.numeric(difftime(fim, inicio, units = "secs"))
      resultado[[paste0("time_", nome_indice)]] <- tempo_segundos
      return(resultado)
    },

    compute_indices = function(indices = private$all_indices) {
      resultados <- list()
      resultados$filename <- private$filename
      resultados$duration <- self$duration()

      funcoes_indices <- list(
        ACI = self$aci,
        NDSI = self$ndsi,
        BIO = self$bio,
        ADI = self$adi,
        AEI = self$aei,
        ENTROPY = self$entropy,
        TEMP_ENT = self$temp_entropy,
        SPEC_ENT = self$spec_entropy,
        MAE = self$mae,
        NP = self$np
      )

      indices_selecionados <- intersect(names(funcoes_indices), indices)

      for (nome_indice in indices_selecionados) {
        f <- funcoes_indices[[nome_indice]]
        res <- self$medir_tempo(f, nome_indice)
        resultados <- c(resultados, res)
      }

      tibble::as_tibble(resultados)
    },

    duration = function() {
      tryCatch({
        seewave::duration(private$wav)
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular duração para", private$filename, "->", e$message))
        NA
      })
    },

    aci = function() {
      tryCatch({
        params <- params_indices$ACI
        res <- soundecology::acoustic_complexity(
          private$wav,
          min_freq = params$min_freq,
          max_freq = params$max_freq,
          fft_w    = params$fft_w,
          j        = params$j
        )
        list(
          ACI_E        = res$AciTotAll_left,
          ACI_D        = res$AciTotAll_right,
          ACI_bymin_E  = res$AciTotAll_left_bymin,
          ACI_bymin_D  = res$AciTotAll_right_bymin
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular ACI para", private$filename, "->", e$message))
        list(ACI_E = NA, ACI_D = NA, ACI_bymin_E = NA, ACI_bymin_D = NA)
      })
    },

    ndsi = function() {
      tryCatch({
        params <- params_indices$NDSI
        res <- soundecology::ndsi(
          private$wav,
          anthro_min = params$anthro_min,
          anthro_max = params$anthro_max,
          bio_min    = params$bio_min,
          bio_max    = params$bio_max,
          fft_w      = params$fft_w
        )
        list(ndsi_E = res$ndsi_left, ndsi_D = res$ndsi_right)
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular NDSI para", private$filename, "->", e$message))
        list(ndsi_E = NA, ndsi_D = NA)
      })
    },

    bio = function() {
      tryCatch({
        params <- params_indices$BIO
        res <- soundecology::bioacoustic_index(
          private$wav,
          min_freq = params$min_freq,
          max_freq = params$max_freq,
          fft_w    = params$fft_w
        )
        list(bio_E = res$left_area, bio_D = res$right_area)
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular BIO para", private$filename, "->", e$message))
        list(bio_E = NA, bio_D = NA)
      })
    },

    adi = function() {
      tryCatch({
        params <- params_indices$ADI_AEI
        res <- soundecology::acoustic_diversity(
          private$wav,
          max_freq     = params$max_freq,
          db_threshold = params$db_threshold,
          freq_step    = params$freq_step
        )
        list(adi_E = res$adi_left, adi_D = res$adi_right)
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular ADI para", private$filename, "->", e$message))
        list(adi_E = NA, adi_D = NA)
      })
    },

    aei = function() {
      tryCatch({
        params <- params_indices$ADI_AEI
        res <- soundecology::acoustic_evenness(
          private$wav,
          max_freq     = params$max_freq,
          db_threshold = params$db_threshold,
          freq_step    = params$freq_step
        )
        list(aei_E = res$aei_left, aei_D = res$aei_right)
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular AEI para", private$filename, "->", e$message))
        list(aei_E = NA, aei_D = NA)
      })
    },

    entropy = function() {
      params <- params_indices$ENTROPY
      tryCatch({
        calcular_entropy <- function(channel) {
          seewave::H(
            wave = private$wav,
            f    = private$wav@samp.rate,
            channel = channel,
            wl   = params$wl
          )
        }
        list(
          entropy_E = calcular_entropy(1),
          entropy_D = calcular_entropy(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular ENTROPY para", private$filename, "->", e$message))
        list(entropy_E = NA, entropy_D = NA)
      })
    },

    temp_entropy = function() {
      tryCatch({
        calcular_th <- function(channel) {
          enve <- seewave::env(
            private$wav,
            f = private$wav@samp.rate,
            envt = "abs",
            plot = FALSE,
            channel = channel
          )
          seewave::th(enve)
        }
        list(
          temp_entropy_E = calcular_th(1),
          temp_entropy_D = calcular_th(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular TEMP_ENT para", private$filename, "->", e$message))
        list(temp_entropy_E = NA, temp_entropy_D = NA)
      })
    },

    spec_entropy = function() {
      params <- params_indices$SPEC_ENT
      tryCatch({
        calcular_sh <- function(channel) {
          spec <- seewave::meanspec(
            private$wav,
            wl = params$wl,
            ovlp = params$ovlp,
            plot = FALSE,
            channel = channel,
            f = private$wav@samp.rate
          )
          seewave::sh(spec)
        }
        list(
          spec_entropy_E = calcular_sh(1),
          spec_entropy_D = calcular_sh(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular SPEC_ENT para", private$filename, "->", e$message))
        list(spec_entropy_E = NA, spec_entropy_D = NA)
      })
    },

    mae = function() {
      tryCatch({
        calcular_mae <- function(channel) {
          seewave::M(private$wav, channel = channel)
        }
        list(
          mae_E = calcular_mae(1),
          mae_D = calcular_mae(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular MAE para", private$filename, "->", e$message))
        list(mae_E = NA, mae_D = NA)
      })
    },

    np = function() {
      params <- params_indices$SPEC_ENT
      tryCatch({
        calcular_np <- function(channel) {
          spec <- seewave::meanspec(
            private$wav,
            wl = params$wl,
            ovlp = params$ovlp,
            plot = FALSE,
            channel = channel,
            f = private$wav@samp.rate
          )
          nrow(seewave::fpeaks(spec, plot = FALSE))
        }
        list(
          np_E = calcular_np(1),
          np_D = calcular_np(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Erro ao calcular NP para", private$filename, "->", e$message))
        list(np_E = NA, np_D = NA)
      })
    }
  )
)