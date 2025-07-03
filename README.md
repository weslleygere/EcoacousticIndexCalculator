# Acoustic_Indices_Calculation

An efficient and modular R-based pipeline for computing acoustic indices from stereo `.wav` files, designed for ecological soundscape analysis. Supports batch processing, parallel execution, parameter validation, runtime logging, and is ready for integration in HPC environments.

## 📦 Features

- Calculates a wide range of ecoacoustic indices:
  - ACI, ADI, AEI, BIO, NDSI (via `soundecology`)
  - Entropy, Spectral peaks, and other complementary metrics (via `seewave`)
- Stereo audio support (left and right channels independently)
- Batch processing via command-line arguments
- Parallel execution with `furrr` and `future`
- Per-file runtime monitoring
- Logging to structured `.log` files (via `log4r`)
- Output in efficient `.parquet` format (`arrow`)
