#' IndexCalculator: Computes acoustic indices from a wave object
#'
#' This class encapsulates the logic for computing multiple ecoacoustic indices
#' from a stereo WAV file, using the `soundecology` and `seewave` packages.
#'
#' @field filename Path of the WAV file
#' @field wav A `tuneR::Wave` object
#' @field logger Optional logger object for error reporting
#' @export
IndexCalculator <- R6::R6Class("IndexCalculator",
  private = list(
    filename = NULL,
    wav = NULL,
    logger = NULL,

    all_indices = c(
      "ACI",
      "NDSI",
      "BIO",
      "ADI",
      "AEI",
      "ENTROPY",
      "TEMP_ENT",
      "SPEC_ENT",
      "MAE",
      "NP"
    )
  ),

  public = list(

    #' @description Constructor
    #' @param filename File path of the original audio
    #' @param wav The wave object (tuneR::Wave)
    #' @param logger Optional logger for error reporting
    initialize = function(filename, wav, logger = NULL) {
      private$filename <- filename
      private$wav <- wav
      private$logger <- logger
    },

    #' Measure execution time of a function and attach it to the result
    #' @param func The function to execute
    #' @param index_name Name of the index (used for naming the timing field)
    #' @return A named list with results and processing time
    measure_time = function(func, index_name) {
      start <- Sys.time()
      result <- func()
      end <- Sys.time()
      duration_sec <- as.numeric(difftime(end, start, units = "secs"))
      result[[paste0("time_", index_name)]] <- duration_sec
      return(result)
    },

    #' Compute the selected acoustic indices
    #' @param indices Vector of index names to compute (default: all)
    #' @return A tibble with the results
    compute_indices = function(indices = private$all_indices) {
      results <- list(
        filename = private$filename,
        duration = self$duration()
      )

      index_functions <- list(
        ACI        = self$aci,
        NDSI       = self$ndsi,
        BIO        = self$bio,
        ADI        = self$adi,
        AEI        = self$aei,
        ENTROPY    = self$entropy,
        TEMP_ENT   = self$temp_entropy,
        SPEC_ENT   = self$spec_entropy,
        MAE        = self$mae,
        NP         = self$np
      )

      selected <- intersect(names(index_functions), indices)

      for (index_name in selected) {
        f <- index_functions[[index_name]]
        res <- self$measure_time(f, index_name)
        results <- c(results, res)
      }

      tibble::as_tibble(results)
    },

    #' Get the duration of the WAV file
    duration = function() {
      tryCatch({
        seewave::duration(private$wav)
      }, error = function(e) {
        private$logger$error(paste("Failed to compute duration for", private$filename, "->", e$message))
        NA
      })
    },

    #' Compute Acoustic Complexity Index (ACI)
    aci = function() {
      tryCatch({
        params <- params$ACI
        res <- soundecology::acoustic_complexity(
          private$wav,
          min_freq = params$min_freq,
          max_freq = params$max_freq,
          fft_w    = params$fft_w,
          j        = params$j
        )
        list(
          ACI_E = res$AciTotAll_left,
          ACI_D = res$AciTotAll_right,
          ACI_bymin_E = res$AciTotAll_left_bymin,
          ACI_bymin_D = res$AciTotAll_right_bymin
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute ACI for", private$filename, "->", e$message))
        list(ACI_E = NA, ACI_D = NA, ACI_bymin_E = NA, ACI_bymin_D = NA)
      })
    },

    #' Compute Normalized Difference Soundscape Index (NDSI)
    ndsi = function() {
      tryCatch({
        params <- params$NDSI
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
        private$logger$error(paste("Failed to compute NDSI for", private$filename, "->", e$message))
        list(ndsi_E = NA, ndsi_D = NA)
      })
    },

    #' Compute Bioacoustic Index (BIO)
    bio = function() {
      tryCatch({
        params <- params$BIO
        res <- soundecology::bioacoustic_index(
          private$wav,
          min_freq = params$min_freq,
          max_freq = params$max_freq,
          fft_w    = params$fft_w
        )
        list(bio_E = res$left_area, bio_D = res$right_area)
      }, error = function(e) {
        private$logger$error(paste("Failed to compute BIO for", private$filename, "->", e$message))
        list(bio_E = NA, bio_D = NA)
      })
    },

    #' Compute Acoustic Diversity Index (ADI)
    adi = function() {
      tryCatch({
        params <- params$ADI_AEI
        res <- soundecology::acoustic_diversity(
          private$wav,
          max_freq     = params$max_freq,
          db_threshold = params$db_threshold,
          freq_step    = params$freq_step
        )
        list(adi_E = res$adi_left, adi_D = res$adi_right)
      }, error = function(e) {
        private$logger$error(paste("Failed to compute ADI for", private$filename, "->", e$message))
        list(adi_E = NA, adi_D = NA)
      })
    },

    #' Compute Acoustic Evenness Index (AEI)
    aei = function() {
      tryCatch({
        params <- params$ADI_AEI
        res <- soundecology::acoustic_evenness(
          private$wav,
          max_freq     = params$max_freq,
          db_threshold = params$db_threshold,
          freq_step    = params$freq_step
        )
        list(aei_E = res$aei_left, aei_D = res$aei_right)
      }, error = function(e) {
        private$logger$error(paste("Failed to compute AEI for", private$filename, "->", e$message))
        list(aei_E = NA, aei_D = NA)
      })
    },

    #' Compute Entropy Index (Shannon Entropy)
    entropy = function() {
      params <- params$ENTROPY
      tryCatch({
        compute_entropy <- function(channel) {
          seewave::H(
            wave = private$wav,
            f    = private$wav@samp.rate,
            channel = channel,
            wl   = params$wl
          )
        }
        list(
          entropy_E = compute_entropy(1),
          entropy_D = compute_entropy(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute ENTROPY for", private$filename, "->", e$message))
        list(entropy_E = NA, entropy_D = NA)
      })
    },

    #' Compute Temporal Entropy
    temp_entropy = function() {
      tryCatch({
        compute_th <- function(channel) {
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
          temp_entropy_E = compute_th(1),
          temp_entropy_D = compute_th(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute TEMP_ENT for", private$filename, "->", e$message))
        list(temp_entropy_E = NA, temp_entropy_D = NA)
      })
    },

    #' Compute Spectral Entropy
    spec_entropy = function() {
      params <- params$SPEC_ENT
      tryCatch({
        compute_sh <- function(channel) {
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
          spec_entropy_E = compute_sh(1),
          spec_entropy_D = compute_sh(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute SPEC_ENT for", private$filename, "->", e$message))
        list(spec_entropy_E = NA, spec_entropy_D = NA)
      })
    },

    #' Compute Amplitude Envelope Mean (MAE)
    mae = function() {
      tryCatch({
        compute_mae <- function(channel) {
          seewave::M(private$wav, channel = channel)
        }
        list(
          mae_E = compute_mae(1),
          mae_D = compute_mae(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute MAE for", private$filename, "->", e$message))
        list(mae_E = NA, mae_D = NA)
      })
    },

    #' Compute Number of Peaks (NP) in spectrum
    np = function() {
      params <- params$SPEC_ENT
      tryCatch({
        compute_np <- function(channel) {
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
          np_E = compute_np(1),
          np_D = compute_np(2)
        )
      }, error = function(e) {
        private$logger$error(paste("Failed to compute NP for", private$filename, "->", e$message))
        list(np_E = NA, np_D = NA)
      })
    }
  )
)