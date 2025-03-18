

kuzuConnect <- function(path="",read_only=FALSE){
  reticulate::source_python("inst/kuzuConnect.py")

  tryCatch(
    {
      conn <- kuzuConnect_py(path = path, read_only = read_only)
      cli::cli_alert_success("Kuzu connenction with Database:{path} established.")

      return(conn)
    },
    error = function(e)
      cli::cli_alert_warning("Kuzu connenction with Database:{path} already established. Restart Session for new connection")
    )
}

