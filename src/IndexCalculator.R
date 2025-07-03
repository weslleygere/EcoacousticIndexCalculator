index_calculator <- R6::R6Class("IndexCalculator",
  public = list(
    wav = NULL,

    initialize = function(wav) {
      self$wav <- wav
    },

    # Função principal: calcula todos os índices para ambos os canais
    compute_all = function() {
      log_info("Iniciando cálculo dos índices")
      tibble::tibble(
        duration     = self$safe_duration(),

        # Índices soundecology
        ACI_E        = self$safe_aci(1),
        ACI_D        = self$safe_aci(2),
        ACI_j60_E    = self$safe_aci_j60(1),
        ACI_j60_D    = self$safe_aci_j60(2),
        NDSI_E       = self$safe_ndsi(1),
        NDSI_D       = self$safe_ndsi(2),
        BIO_E        = self$safe_bio(1),
        BIO_D        = self$safe_bio(2),
        ADI_E        = self$safe_adi(1),
        ADI_D        = self$safe_adi(2),
        AEI_E        = self$safe_aei(1),
        AEI_D        = self$safe_aei(2),

        # Índices seewave
        ENTROPY_E    = self$safe_entropy(1),
        ENTROPY_D    = self$safe_entropy(2),
        TEMP_ENT_E   = self$safe_temp_entropy(1),
        TEMP_ENT_D   = self$safe_temp_entropy(2),
        SPEC_ENT_E   = self$safe_spec_entropy(1),
        SPEC_ENT_D   = self$safe_spec_entropy(2),
        MAE_E        = self$safe_mae(1),
        MAE_D        = self$safe_mae(2),
        NP_E         = self$safe_np(1),
        NP_D         = self$safe_np(2)
      )
    },

    # --- Funções soundecology ---

    safe_duration = function() tryCatch(seewave::duration(self$wav), error = function(e) NA),

    safe_aci = function(channel) {
      tryCatch({
        res <- soundecology::acoustic_complexity(self$wav, fft_w = fft_w)
        if (channel == 1) res$AciTotAll_left else res$AciTotAll_right
      }, error = function(e) NA)
    },

    safe_aci_j60 = function(channel) {
      tryCatch({
        res <- soundecology::acoustic_complexity(self$wav, fft_w = fft_w, j = j)
        if (channel == 1) res$AciTotAll_left else res$AciTotAll_right
      }, error = function(e) NA)
    },

    safe_ndsi = function(channel) {
      tryCatch({
        res <- soundecology::ndsi(self$wav, fft_w = fft_w)
        if (channel == 1) res$ndsi_left else res$ndsi_right
      }, error = function(e) NA)
    },

    safe_bio = function(channel) {
      tryCatch({
        res <- soundecology::bioacoustic_index(self$wav, min_freq = bio_min_freq, max_freq = bio_max_freq, fft_w = fft_w)
        if (channel == 1) res$left_area else res$right_area
      }, error = function(e) NA)
    },

    safe_adi = function(channel) {
      tryCatch({
        res <- soundecology::acoustic_diversity(self$wav, max_freq = max_freq, freq_step = freq_step)
        if (channel == 1) res$adi_left else res$adi_right
      }, error = function(e) NA)
    },

    safe_aei = function(channel) {
      tryCatch({
        res <- soundecology::acoustic_evenness(self$wav, max_freq = max_freq, freq_step = freq_step)
        if (channel == 1) res$aei_left else res$aei_right
      }, error = function(e) NA)
    },

    # --- Funções seewave ---

    safe_entropy = function(channel) {
      tryCatch({
        seewave::H(self$wav, wl = fft_w, channel = channel)
      }, error = function(e) NA)
    },

    safe_temp_entropy = function(channel) {
      tryCatch({
        seewave::th(seewave::env(self$wav, fftw = fft_w, j = j, plot = FALSE, channel = channel))
      }, error = function(e) NA)
    },

    safe_spec_entropy = function(channel) {
      tryCatch({
        spec <- seewave::meanspec(self$wav, wl = fft_w, ovlp = ovlp, plot = FALSE, channel = channel, fftw = TRUE)
        seewave::sh(spec)
      }, error = function(e) NA)
    },

    safe_mae = function(channel) {
      tryCatch({
        seewave::M(self$wav, channel = channel)
      }, error = function(e) NA)
    },

    safe_np = function(channel) {
      tryCatch({
        spec <- seewave::meanspec(self$wav, wl = fft_w, ovlp = ovlp, plot = FALSE, channel = channel, fftw = TRUE)
        nrow(seewave::fpeaks(spec, nmax = 5, plot = FALSE))
      }, error = function(e) NA)
    }
  )
)
