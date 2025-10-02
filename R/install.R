#' Install the Kuzu Python package
#'
#' This function checks if the 'kuzu' Python package is available in the current
#' reticulate environment. If not, it will ask for permission to install it
#' using `reticulate::py_install()`.
#'
#' @export
#' @examples
#' \dontrun{
#' install_kuzu()
#' }
install_kuzu <- function() {
  pkgs <- c("kuzu", "pandas", "networkx")
  installed_status <- sapply(pkgs, reticulate::py_module_available)
  
  if (all(installed_status)) {
    message("The 'kuzu', 'pandas', and 'networkx' Python packages are already installed and available.")
    return(invisible(NULL))
  }

  missing_pkgs <- names(installed_status[!installed_status])
  message(paste("The following required Python packages are not installed:", paste(missing_pkgs, collapse = ", ")))
  
  if (interactive()) {
    question <- "Would you like to install them now? (This will use reticulate::py_install)"
    if (utils::askYesNo(question, default = TRUE)) {
      reticulate::py_install(pkgs, pip = TRUE)
    } else {
      message("Installation cancelled by user.")
    }
  } else {
    message("To install the required packages, please run `kuzuR::install_kuzu()` in an interactive R session.")
  }
  
  invisible(NULL)
}
