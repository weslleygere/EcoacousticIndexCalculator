params <- list(

  ACI = list(
    min_freq = 0,
    max_freq = 11000,
    j        = 10,
    fft_w    = 512
  ),

  NDSI = list(
    anthro_min = 0,
    anthro_max = 2000,
    bio_min    = 2000,
    bio_max    = 11000,
    fft_w      = 512
  ),

  BIO = list(
    min_freq = 2000,
    max_freq = 11000,
    fft_w    = 512
  ),

  ADI_AEI = list(
    max_freq     = 11000,
    db_threshold = -50,
    freq_step    = 1000
  ),

  ENTROPY = list(
    wl = 512
  ),

  TEMP_ENT = list(
    # usa seewave::env, não exige parâmetros extras neste momento
  ),

  SPEC_ENT = list(
    wl   = 512,
    ovlp = 0
  ),

  MAE = list(
    # seewave::M não exige parâmetros além do canal
  ),

  NP = list(
    wl   = 512,
    ovlp = 0
  )
)