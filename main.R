# main.R — Entry point for batch ecoacoustic index processing

# ==== 1. Load sources ====
source("src/Logger.R")
source("src/AudioProcessor.R")
source("src/IndexCalculator.R")
source("src/ParallelRunner.R")
source("src/Pipeline.R")

# ==== 2. Run the pipeline ====
pipeline <- Pipeline$new()
pipeline$run()