# 🎧 Acoustic Indices Calculator

An efficient, modular, and HPC-ready R project for computing ecoacoustic indices from stereo `.wav` files — ideal for soundscape analysis in ecological research.

This project provides tools for **batch audio processing**, **index computation**, and **runtime monitoring**, with **parallel execution** support and detailed logging. It integrates key ecoacoustic packages such as `soundecology`, `seewave`, and `tuneR`.

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
  Rscript scripts/main.R <folder> [index1 index2 ...] --range <start> <end>
  ```

- 🧵 **Parallel computation** using `furrr` + `future`

- ⏱️ **Per-file runtime tracking**

- 📝 **Structured logging** with `log4r` (separate logs for loading, processing, and orchestration)

- 💾 **Output in `.parquet` format** via `arrow` (highly compressed and analytics-friendly)

- 🎯 **Clean console output** with progress bars and informative messages

---

## 📁 Directory structure

```
IndexCalculator/
├── src/                     # R6 classes source code
│   ├── AudioProcessor.R     # Audio loading and preprocessing
│   ├── IndexCalculator.R    # Index computation methods
│   ├── JobRunner.R          # Parallel processing orchestration
│   └── Logger.R             # Logging utilities
├── scripts/                 # Main CLI entry point
│   └── main.R               # Command-line interface
├── indices_parameters/      # Customizable parameters for index calculations
│   └── params.R             # Parameter definitions
├── data/                    # Input data and results
│   ├── audios/              # Audio files (.wav)
│   ├── results/             # Output files (.parquet)
│   └── log/                 # Log files
├── renv/                    # Project-local R environment
├── renv.lock                # Dependency lock file
├── .Rprofile                # R startup configuration
├── .gitignore               # Git ignore patterns
└── README.md                # This file
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

3. **Run the main script**:
   ```bash
   # Windows PowerShell
   & "C:\Program Files\R\R-4.5.1\bin\Rscript.exe" scripts/main.R "data/audios/20240923" ACI --range 1 10
   
   # Linux/macOS
   Rscript scripts/main.R data/audios/20240923 ACI --range 1 10
   ```

4. **Check logs and outputs**:
   - Logs in `data/log/`
   - Output `.parquet` files in `data/results/`

---

## 🔧 Requirements

- **R ≥ 4.5** (recommended for best compatibility)
- **Rtools** (Windows only, for package compilation)
- **Dependencies** (automatically managed by `renv`):
  - `soundecology`, `seewave`, `tuneR` (audio processing)
  - `log4r`, `arrow`, `furrr`, `future`, `tibble` (utilities)
  - `R6`, `dplyr`, `purrr` (programming)

> All dependencies are managed with [`renv`](https://rstudio.github.io/renv/). The environment will be activated automatically when you start R in this project directory.

---

## 🎯 Usage Examples

### Basic usage (single index):
```bash
Rscript scripts/main.R "data/audios/20240923" ACI
```

### Multiple indices:
```bash
Rscript scripts/main.R "data/audios/20240923" ACI NDSI BIO
```

### Process specific file range:
```bash
Rscript scripts/main.R "data/audios/20240923" ACI --range 1 10
```

### Process all files with all indices:
```bash
Rscript scripts/main.R "data/audios/20240923"
```

---

## � Output Format

Results are saved as `.parquet` files with the following naming convention:
```
indices_<folder_name>_<range>_<timestamp>.parquet
```

Example: `indices_20240923_1-10_20250707_182101.parquet`

The output contains:
- **Metadata**: filename, processing timestamps
- **Index values**: for left and right channels
- **Processing times**: per-index computation duration

---

## 📚 Architecture

The project uses a modular **R6 class-based architecture**:

- **`AudioProcessor`**: Handles `.wav` file loading and preprocessing
- **`IndexCalculator`**: Computes individual acoustic indices with error handling
- **`JobRunner`**: Orchestrates parallel processing of multiple files
- **`Logger`**: Provides structured logging with different log levels

All classes are thoroughly documented and designed for extensibility and maintainability.

---

## 🛠️ Development

### Adding new indices:
1. Add the computation method to `IndexCalculator.R`
2. Update the `all_indices` list
3. Add parameters to `indices_parameters/params.R`

### Customizing parameters:
Edit `indices_parameters/params.R` to modify frequency ranges, FFT windows, and other computation parameters.

### Logging:
Logs are automatically generated in `data/log/` with separate files for different components.

---

## 📝 License

This project is provided as-is for research and educational purposes.

---

## 🙏 Acknowledgments

Built with these excellent R packages:
- [`soundecology`](https://cran.r-project.org/package=soundecology) - Core acoustic indices
- [`seewave`](https://cran.r-project.org/package=seewave) - Sound analysis and synthesis
- [`tuneR`](https://cran.r-project.org/package=tuneR) - Audio processing
- [`furrr`](https://cran.r-project.org/package=furrr) - Parallel processing
- [`arrow`](https://cran.r-project.org/package=arrow) - Efficient data storage
