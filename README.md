# 🎧 Acoustic Indices Calculator

An efficient, modular, and HPC-ready R project for computing ecoacoustic indices from stereo `.wav` files — ideal for soundscape analysis in ecological research.

This project provides tools for **batch audio processing**, **comprehensive index computation**, and **runtime monitoring**, with **parallel execution** support and detailed logging. It integrates key ecoacoustic packages such as `soundecology`, `seewave`, and `tuneR`.

---

## 🚀 Features

- ✅ **Comprehensive ecoacoustic index computation** from stereo audio:
  - **From `soundecology`**:  
    - ACI (Acoustic Complexity Index)  
    - ADI (Acoustic Diversity Index)  
    - AEI (Acoustic Evenness Index)  
    - BIO (Bioacoustic Index)  
    - NDSI (Normalized Difference Soundscape Index)
  - **From `seewave`**:
    - ENTROPY (Shannon entropy)
    - TEMP_ENT (Temporal entropy)
    - SPEC_ENT (Spectral entropy)
    - MAE (Mean Amplitude Envelope)
    - NP (Number of Peaks in spectrum)
    - SPECFLUX (Spectral Flux)
    - SPECPROP (Spectral Properties: centroid, skewness, kurtosis, SFM)
  - **From `tuneR`**:
    - MFCC (Mel-Frequency Cepstral Coefficients)

- 🎙️ **Stereo channel support** (left "_E" and right "_D" processed independently)

- ⚙️ **Flexible batch processing** via command-line:

  ```bash
  Rscript main.R -d <directory> -i IDX1,IDX2,... -r START,END
  ```

- 🧵 **Parallel computation** using `furrr` + `future` with automatic core detection

- ⏱️ **Per-file and per-index runtime tracking**

- 📝 **Structured logging** with `log4r` (separate logs for pipeline, audio loading, and index calculation)

- 💾 **Efficient output** in `.parquet` format via `arrow` (highly compressed and analytics-friendly)

- 🎯 **Clean console output** with progress bars and informative status messages

- 📊 **Comprehensive metadata** including processing status, timing, and error details

---

## 📁 Directory structure

```text
IndexCalculator/
├── src/                              # R6 classes source code
│   ├── AudioProcessor.R              # Audio loading and validation
│   ├── IndexCalculator.R             # Comprehensive index computation methods
│   ├── ParallelRunner.R              # Parallel processing orchestration
|   ├── Logger.R                      # Structured logging utilities
│   └── Pipeline.R                    # Pipeline for job runner
├── main.R                            # Main CLI entry point
├── indices_parameters/               # Configurable computation parameters
│   └── params.json                   # JSON parameter definitions for all indices
├── data/                             # Input data and outputs
│   ├── audios/                       # Audio files (.wav)
│   │   └── 20240923/                 # Example audio folder
│   ├── results/                      # Output files (.parquet)
│   └── log/                          # Structured log files
│       ├── log_main.txt              # Main execution log
│       ├── log_parallel_runner.txt   # Parallel orchestration log
│       ├── log_audio_load.txt        # Audio loading log
│       └── log_index_calc.txt        # Index calculation log
├── renv/                             # Project-local R environment
├── renv.lock                         # Dependency lock file
├── .Rprofile                         # R startup configuration
├── slurm_batchtools.tmpl             # HPC cluster job template
├── .gitignore                        # Git ignore patterns
└── README.md                         # This file
```

---

## ⚡ Quick start

1. **Clone or download the project**:

   ```bash
   git clone <repository-url>
   cd IndexCalculator
   ```

2. **Set up the R environment**:

   ```r
   # The renv will activate automatically via .Rprofile
   # If needed, restore dependencies:
   renv::restore()
   ```

3. **Prepare your audio files**:
   - Place `.wav` files in `data/audios/<folder_name>/`
   - Ensure files are readable and in supported format

4. **Run the main script**:

   ```bash
   # Windows PowerShell
   Rscript main.R -d "data/audios/20240923" -i ACI,NDSI -r 1,10

   # Linux/macOS
   Rscript main.R -d data/audios/20240923 -i ACI,NDSI -r 1,10
   ```

5. **Check results**:
   - Logs in `data/log/` for detailed processing information
   - Output `.parquet` files in `data/results/`
   - Monitor progress via console output

---

## 🔧 Requirements

- **R ≥ 4.4** (tested with R 4.5)
- **Rtools** (Windows only, for package compilation)
- **System memory**: Recommended 8GB+ for large audio files
- **Dependencies** (automatically managed by `renv`):
  - **Audio processing**: `soundecology`, `seewave`, `tuneR`
  - **Parallel computing**: `furrr`, `future`
  - **Data handling**: `arrow`, `tibble`, `dplyr`, `purrr`
  - **Utilities**: `log4r`, `jsonlite`, `glue`
  - **Framework**: `R6`

> All dependencies are managed with [`renv`](https://rstudio.github.io/renv/). The environment will be activated automatically when you start R in this project directory.

---

## 🎯 Usage Examples

### Process all indices (default behavior)

```bash
Rscript main.R -d "data/audios/20240923"
```

### Single index computation

```bash
Rscript main.R -d "data/audios/20240923" -i ACI
```

### Multiple specific indices

```bash
Rscript main.R -d "data/audios/20240923" -i ACI,NDSI,BIO,SPECPROP,MFCC
```

### Process specific file range

```bash
Rscript main.R -d "data/audios/20240923" -r 1,50
```

### Complex combination

```bash
Rscript main.R -d "data/audios/20240923" -i ENTROPY,SPEC_ENT,MFCC -r 10,100
```

---

## 📊 Available Indices

| Index | Code | Channels | Description |
|-------|------|----------|-------------|
| Acoustic Complexity | `ACI` | E/D | Complexity based on temporal variation |
| Bioacoustic Index | `BIO` | E/D | Biological activity indicator |
| Normalized Diff. Soundscape | `NDSI` | E/D | Anthrophonic vs biophonic sounds |
| Acoustic Diversity | `ADI` | E/D | Frequency band diversity |
| Acoustic Evenness | `AEI` | E/D | Frequency distribution evenness |
| Shannon Entropy | `ENTROPY` | E/D | Spectral complexity measure |
| Temporal Entropy | `TEMP_ENT` | E/D | Temporal envelope entropy |
| Spectral Entropy | `SPEC_ENT` | E/D | Spectral distribution entropy |
| Mean Amplitude Envelope | `MAE` | E/D | Average amplitude measure |
| Number of Peaks | `NP` | E/D | Spectral peak count |
| Spectral Flux | `SPECFLUX` | E/D | Spectral change measure |
| Spectral Properties | `SPECPROP` | E/D | Centroid, skewness, kurtosis, SFM |
| Mel-Frequency Cepstral Coeffs | `MFCC` | E/D | Perceptual frequency features |

**Note:** E = Left channel (Esquerdo), D = Right channel (Direito)

---

## 📈 Output Format

Results are saved as `.parquet` files with automatic naming:

```bash
indices_<folder_name>_<range>_<timestamp>.parquet
```

Example: `indices_20240923_1-50_20250121_143022.parquet`

### Output Structure

```r
# Core metadata
filename, duration, status, total_processing_time_sec

# Index values (example for ACI)
ACI_E, ACI_D, ACI_bymin_E, ACI_bymin_D

# Spectral properties (8 values)
spec_centroid_E, spec_centroid_D, spec_skewness_E, spec_skewness_D
spec_kurtosis_E, spec_kurtosis_D, spec_sfm_E, spec_sfm_D

# Processing times
time_ACI, time_NDSI, time_BIO, ...

# Error information (when applicable)
error_message
```
