# 🎧 Acoustic Indices Calculation

An efficient, modular, and HPC-ready R pipeline for computing ecoacoustic indices from stereo `.wav` files — ideal for soundscape analysis in ecological research.

This package provides tools for **batch audio processing**, **index computation**, and **runtime monitoring**, with **parallel execution** support and detailed logging. It integrates key ecoacoustic packages such as `soundecology`, `seewave`, and `tuneR`.

---

## 🚀 Features

- ✅ **Ecoacoustic index computation** from stereo audio:
  - **From `soundecology`**:  
    - ACI (Acoustic Complexity Index)  
    - ADI (Acoustic Diversity Index)  
    - AEI (Acoustic Evenness Index)  
    - BIO (Bioacoustic Index)  
    - NDSI (Normalized Difference Soundscape Index)
  - **From `seewave`**:
    - Temporal and spectral entropy  
    - Number of peaks in spectrum  
    - Mean amplitude envelope  
    - Other time-frequency descriptors

- 🎙️ **Stereo channel support** (left and right processed independently)

- ⚙️ **Batch processing** via command-line:
  ```bash
  Rscript main.R <folder> [index1 index2 ...] --range <start> <end>
  ```

- 🧵 **Parallel computation** using `furrr` + `future`

- ⏱️ **Per-file runtime tracking**

- 📝 **Structured logging** with `log4r` (separate logs for loading, processing, and orchestration)

- 💾 **Output in `.parquet` format** via `arrow` (highly compressed and analytics-friendly)

---

## 📁 Directory structure

```
IndexCalculator/
├── R/                    # Package source code (R6 classes)
├── indices_parameters/   # Customizable parameters for index calculations
├── inst/scripts/         # Main CLI entry point (main.R)
├── results/              # Auto-created output folder (not tracked in Git)
├── renv/                 # Project-local R environment (via renv)
├── DESCRIPTION, NAMESPACE, README.md
```

---

## ⚡ Quick start

1. **Install the package** (from the root project folder):

   ```r
   devtools::install()
   ```

2. **Run the main script**:

   ```bash
   Rscript main.R data/ [ACI NDSI] --range 1 10
   ```

3. **Check logs and outputs**:
   - Logs in `log/`
   - Output `.parquet` file in `results/`

---

## 🔧 Requirements

- R ≥ 4.2  
- Suggested packages:
  - `soundecology`, `seewave`, `tuneR`
  - `log4r`, `arrow`, `furrr`, `future`, `tibble`

> All dependencies are managed with [`renv`](https://rstudio.github.io/renv/). Run `renv::restore()` to reproduce the environment.

---

## 📚 Documentation

Each class is implemented using `R6` and thoroughly documented with `roxygen2`.  
Key components include:

- `AudioProcessor`: Loads `.wav` files
- `IndexCalculator`: Computes indices from audio
- `JobRunner`: Orchestrates parallel batch processing
- `Logger`: Simplified logging interface using `log4r`

---
