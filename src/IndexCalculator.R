#' @title IndexCalculator
#' @description Computes acoustic indices from a stereo WAV file using the soundecology and seewave packages. Encapsulates logic for multiple ecoacoustic indices and error handling.
#'
#' @section Fields:
#' \describe{
#'   \item{filename}{Path of the WAV file (basename)}
#'   \item{wav}{A tuneR::Wave object}
#'   \item{logger}{Logger object for error reporting}
#'   \item{params}{List of parameter lists for each index}
#' }
IndexCalculator <- R6::R6Class(
  classname = "IndexCalculator",
  private = list(
    filename = NULL,
    wav      = NULL,
    logger   = NULL,
    params   = NULL,

    #' @description Helper: run an index function with suppression of console output and timing
    #' @param index_name Name of the index
    #' @param fun A no-arg function computing and returning a named list of results
    run_and_time = function(index_name, fun) {
      start <- Sys.time()
      result <- NULL
      capture.output({ result <- fun() }, type = "output")
      duration <- as.numeric(difftime(Sys.time(), start, units = "secs"))
      result[[paste0("time_", index_name)]] <- duration
      result
    },

    #' @description Helper: apply function by channel and name results
    #' @param fun Function to apply, should take channel number as input
    #' @param name Base name for the results (will append _E and _D)
    compute_by_channel = function(fun, name) {
      vals <- vapply(1:2, function(ch) fun(ch), numeric(1))
      setNames(as.list(vals), c(paste0(name, "_E"), paste0(name, "_D")))
    }
  ),

  public = list(
    #' @description Initialize IndexCalculator object
    #' @param filename Basename of the audio file
    #' @param wav A tuneR::Wave object
    #' @param params List of parameters for indices
    #' @param logger Logger object for logging
    initialize = function(filename, wav, params, logger) {
      private$filename <- filename
      private$wav      <- wav
      private$params   <- params
      private$logger   <- logger
    },

    #' @description Compute selected acoustic indices
    #' @param indices Character vector of index names, defaults to names(params)
    #' @return A tibble with results and timing for each index
    compute_indices = function(indices = names(private$params)) {
      res <- list(
        filename = private$filename,
        duration = tryCatch(
          seewave::duration(private$wav),
          error = function(e) {
            private$logger$error(paste("Failed duration for", private$filename, e$message))
            NA_real_
          }
        )
      )

      fns <- list(
        ACI      = self$aci,
        NDSI     = self$ndsi,
        BIO      = self$bio,
        ADI      = self$adi,
        AEI      = self$aei,
        ENTROPY  = self$entropy,
        TEMP_ENT = self$temp_entropy,
        SPEC_ENT = self$spec_entropy,
        MAE      = self$mae,
        NP       = self$np,
        SPECFLUX = self$spec_flux,
        SPECPROP = self$spec_prop,
        MFCC     = self$mfcc
      )

      sel <- intersect(names(fns), indices)
      for (nm in sel) {
        res <- c(res, private$run_and_time(nm, fns[[nm]]))
      }

      tibble::as_tibble(res)
    },

    #' @description Compute Acoustic Complexity Index
    aci = function() {
      tryCatch({
        p <- private$params$ACI
        res <- withCallingHandlers(
          soundecology::acoustic_complexity(
            private$wav,
            min_freq = p$min_freq,
            max_freq = p$max_freq,
            fft_w    = p$fft_w,
            j        = p$j
          ),
          warning = function(w) {
            private$logger$warn(paste("Warning in ACI for", private$filename, w$message))
            invokeRestart("muffleWarning")
          }
        )
        list(
          ACI_E       = res$AciTotAll_left,
          ACI_D       = res$AciTotAll_right,
          ACI_bymin_E = res$AciTotAll_left_bymin,
          ACI_bymin_D = res$AciTotAll_right_bymin
        )
      }, error = function(e) {
        private$logger$error(paste("Failed ACI for", private$filename, e$message))
        setNames(rep(NA_real_, 4), c("ACI_E", "ACI_D", "ACI_bymin_E", "ACI_bymin_D"))
      })
    },

    #' @description Compute Normalized Difference Soundscape Index
    ndsi = function() {
      tryCatch({
        p <- private$params$NDSI
        res <- withCallingHandlers(
          soundecology::ndsi(
            private$wav,
            anthro_min = p$anthro_min,
            anthro_max = p$anthro_max,
            bio_min    = p$bio_min,
            bio_max    = p$bio_max,
            fft_w      = p$fft_w
          ),
          warning = function(w) {
            private$logger$warn(paste("Warning in NDSI for", private$filename, w$message))
            invokeRestart("muffleWarning")
          }
        )
        list(ndsi_E = res$ndsi_left, ndsi_D = res$ndsi_right)
      }, error = function(e) {
        private$logger$error(paste("Failed NDSI for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("ndsi_E", "ndsi_D"))
      })
    },

    #' @description Compute Bioacoustic Index
    bio = function() {
      tryCatch({
        p <- private$params$BIO
        res <- withCallingHandlers(
          soundecology::bioacoustic_index(
            private$wav,
            min_freq = p$min_freq,
            max_freq = p$max_freq,
            fft_w    = p$fft_w
          ),
          warning = function(w) {
            private$logger$warn(paste("Warning in BIO for", private$filename, w$message))
            invokeRestart("muffleWarning")
          }
        )
        list(bio_E = res$left_area, bio_D = res$right_area)
      }, error = function(e) {
        private$logger$error(paste("Failed BIO for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("bio_E", "bio_D"))
      })
    },

    #' @description Compute Acoustic Diversity Index
    adi = function() {
      tryCatch({
        p <- private$params$ADI
        res <- withCallingHandlers(
          soundecology::acoustic_diversity(
            private$wav,
            max_freq     = p$max_freq,
            db_threshold = p$db_threshold,
            freq_step    = p$freq_step
          ),
          warning = function(w) {
            private$logger$warn(paste("Warning in ADI for", private$filename, w$message))
            invokeRestart("muffleWarning")
          }
        )
        list(adi_E = res$adi_left, adi_D = res$adi_right)
      }, error = function(e) {
        private$logger$error(paste("Failed ADI for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("adi_E", "adi_D"))
      })
    },

    #' @description Compute Acoustic Evenness Index
    aei = function() {
      tryCatch({
        p <- private$params$AEI
        res <- withCallingHandlers(
          soundecology::acoustic_evenness(
            private$wav,
            max_freq     = p$max_freq,
            db_threshold = p$db_threshold,
            freq_step    = p$freq_step
          ),
          warning = function(w) {
            private$logger$warn(paste("Warning in AEI for", private$filename, w$message))
            invokeRestart("muffleWarning")
          }
        )
        list(aei_E = res$aei_left, aei_D = res$aei_right)
      }, error = function(e) {
        private$logger$error(paste("Failed AEI for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("aei_E", "aei_D"))
      })
    },

    #' @description Compute Entropy (Shannon)
    entropy = function() {
      tryCatch({
        p <- private$params$ENTROPY
        private$compute_by_channel(function(ch) {
          seewave::H(wave = private$wav, f = private$wav@samp.rate, channel = ch, wl = p$wl)
        }, "entropy")
      }, error = function(e) {
        private$logger$error(paste("Failed ENTROPY for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("entropy_E", "entropy_D"))
      })
    },

    #' @description Compute Temporal Entropy
    temp_entropy = function() {
      tryCatch({
        private$compute_by_channel(function(ch) {
          enve <- seewave::env(private$wav, f = private$wav@samp.rate, envt = "abs", plot = FALSE, channel = ch)
          seewave::th(enve)
        }, "temp_entropy")
      }, error = function(e) {
        private$logger$error(paste("Failed TEMP_ENT for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("temp_entropy_E", "temp_entropy_D"))
      })
    },

    #' @description Compute Spectral Entropy
    spec_entropy = function() {
      tryCatch({
        p <- private$params$SPEC_ENT
        private$compute_by_channel(function(ch) {
          spec <- seewave::meanspec(private$wav, f = private$wav@samp.rate, wl = p$wl, ovlp = p$ovlp, plot = FALSE, channel = ch)
          seewave::sh(spec)
        }, "spec_entropy")
      }, error = function(e) {
        private$logger$error(paste("Failed SPEC_ENT for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("spec_entropy_E", "spec_entropy_D"))
      })
    },

    #' @description Compute Amplitude Envelope Mean
    mae = function() {
      tryCatch({
        private$compute_by_channel(function(ch) seewave::M(private$wav, channel = ch), "mae")
      }, error = function(e) {
        private$logger$error(paste("Failed MAE for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("mae_E", "mae_D"))
      })
    },

    #' @description Compute Number of Peaks in spectrum
    np = function() {
      tryCatch({
        p <- private$params$SPEC_ENT
        private$compute_by_channel(function(ch) {
          spec <- seewave::meanspec(private$wav, f = private$wav@samp.rate, wl = p$wl, ovlp = p$ovlp, plot = FALSE, channel = ch)
          nrow(seewave::fpeaks(spec, plot = FALSE))
        }, "np")
      }, error = function(e) {
        private$logger$error(paste("Failed NP for", private$filename, e$message))
        setNames(rep(NA_integer_, 2), c("np_E", "np_D"))
      })
    },

    #' @description Compute Spectral Flux index
    spec_flux = function() {
      tryCatch({
        p <- private$params$SPECFLUX
        private$compute_by_channel(function(ch) {
          flux <- seewave::specflux(private$wav, f = private$wav@samp.rate, wl = p$wl, ovlp = p$ovlp, plot = FALSE, channel = ch)
          sum(flux[, 2], na.rm = TRUE)
        }, "spec_flux")
      }, error = function(e) {
        private$logger$error(paste("Failed SPECFLUX for", private$filename, e$message))
        setNames(rep(NA_real_, 2), c("spec_flux_E", "spec_flux_D"))
      })
    },

    #' @description Compute Spectral Properties
    spec_prop = function() {
      tryCatch({
        p <- private$params$SPECPROP

        vals <- lapply(1:2, function(ch) {
          spec <- seewave::meanspec(private$wav, f = private$wav@samp.rate, wl = p$wl, ovlp = p$ovlp, plot = FALSE, channel = ch)
          sp <- seewave::specprop(spec, f = private$wav@samp.rate)

          c(centroid = sp$cent, skewness = sp$skewness, kurtosis = sp$kurtosis, sfm = sp$sfm)
        })

        list(
          spec_centroid_E = as.numeric(vals[[1]]["centroid"]),
          spec_centroid_D = as.numeric(vals[[2]]["centroid"]),
          spec_skewness_E = as.numeric(vals[[1]]["skewness"]),
          spec_skewness_D = as.numeric(vals[[2]]["skewness"]),
          spec_kurtosis_E = as.numeric(vals[[1]]["kurtosis"]),
          spec_kurtosis_D = as.numeric(vals[[2]]["kurtosis"]),
          spec_sfm_E = as.numeric(vals[[1]]["sfm"]),
          spec_sfm_D = as.numeric(vals[[2]]["sfm"])
        )
      }, error = function(e) {
        private$logger$error(paste("Failed SPECPROP for", private$filename, e$message))
        setNames(rep(NA_real_, 8), c(
          "spec_centroid_E", "spec_centroid_D",
          "spec_skewness_E", "spec_skewness_D",
          "spec_kurtosis_E", "spec_kurtosis_D",
          "spec_sfm_E", "spec_sfm_D"
        ))
      })
    },

    #' @description Compute MFCC
    mfcc = function() {
      tryCatch({
        p <- private$params$MFCC
        private$compute_by_channel(function(ch) {
          wav_mono <- tuneR::mono(private$wav, which = if (ch == 1) "left" else "right")

          mfcc_result <- tuneR::melfcc(
            wav_mono,
            sr = private$wav@samp.rate,
            wintime = p$fft_w / private$wav@samp.rate,
            hoptime = (p$fft_w * (1 - p$ovlp / 100)) / private$wav@samp.rate,
            numcep = p$ncoef,
            minfreq = p$min_freq,
            maxfreq = p$max_freq,
            nbands = p$nbands,
            frames_in_rows = TRUE
          )

          if (is.matrix(mfcc_result)) {
            mean(colMeans(mfcc_result, na.rm = TRUE), na.rm = TRUE)
          } else {
            mean(as.numeric(mfcc_result), na.rm = TRUE)
          }
        }, "mfcc")
      }, error = function(e) {
        private$logger$error(paste("Failed MFCC for", private$filename, ":", e$message))
        setNames(rep(NA_real_, 2), c("mfcc_E", "mfcc_D"))
      })
    }
  )
)