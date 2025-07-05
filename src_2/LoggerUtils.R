Logger <- R6::R6Class("Logger",
  private = list(
    logger = NULL
  ),

  public = list(
    initialize = function(logfile = "log.txt", level = "INFO", global_name = "logger") {
      # Extrai o diretório do caminho do log
      log_dir <- dirname(logfile)

      # Cria o diretório, se necessário
      if (!dir.exists(log_dir)) {
        dir.create(log_dir, recursive = TRUE)
      }

      # Inicializa o logger
      private$logger <- log4r::create.logger()
      log4r::logfile(private$logger) <- logfile
      log4r::level(private$logger) <- level

      # Coloca o logger no ambiente global
      assign(global_name, self, envir = .GlobalEnv)
    },

    # Método genérico para logar mensagens com categorias específicas
    log = function(level, msg) {
      full_msg <- paste(Sys.time(), "|", msg)

      switch(level,
        info  = log4r::info(private$logger, full_msg),
        warn  = log4r::warn(private$logger, full_msg),
        error = log4r::error(private$logger, full_msg),
        stop("Categoria de log inválida: use 'info', 'warn' ou 'error'")
      )
    },

    info = function(msg) {
      self$log("info", msg)
    },

    warn = function(msg) {
      self$log("warn", msg)
    },

    error = function(msg) {
      self$log("error", msg)
    }
  )
)
