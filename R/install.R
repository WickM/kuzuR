#' Check for Kuzu Python Dependencies
#'
#' This function checks if the required Python packages (`kuzu`, `pandas`,
#' `networkx`) are available in the user's `reticulate` environment. If any
#' packages are missing, it provides a clear, actionable message guiding the
#' user on how to install them manually.
#'
#' @export
#' @return `NULL` invisibly. The function is called for its side effect of
#'   checking dependencies and printing messages.
#' @examples
#' \donttest{
#' check_kuzu_installation()
#' }
check_kuzu_installation <- function() {
  pkgs <- c("kuzu", "pandas", "networkx")
  installed_status <- sapply(pkgs, reticulate::py_module_available)

  if (all(installed_status)) {
    message(
      "The 'kuzu', 'pandas', and 'networkx' Python packages are installed and available."
    )
    return(invisible(NULL))
  }

  missing_pkgs <- names(installed_status[!installed_status])
  
  # Construct the error message
  error_msg <- paste(
    "The following required Python packages are not installed:",
    paste(missing_pkgs, collapse = ", "),
    "\nTo install them, please run the following command in your R console:",
    sprintf('\nreticulate::py_install(c("%s"), pip = TRUE)', paste(missing_pkgs, collapse = '", "'))
  )
  
  stop(error_msg, call. = FALSE)
  
  invisible(NULL)
}
