#' Check for Kuzu Python Dependencies
#'
#' This function checks if the required Python package (`kuzu`) is available
#' in the user's `reticulate` environment. If the package is missing, it
#' provides a clear, actionable message guiding the user on how to install
#' it manually.
#'
#' @export
#' @return `NULL` invisibly. The function is called for its side effect of
#'   checking dependencies and printing messages.
#' @examples
#' \donttest{
#' check_kuzu_installation()
#' }
check_kuzu_installation <- function() {
  if (!reticulate::py_module_available("kuzu")) {
    stop(
      "The 'kuzu' Python package is not installed.",
      "\nTo install it, please run the following command in your R console:",
      "\nreticulate::py_install('kuzu', pip = TRUE)",
      call. = FALSE
    )
  }
  
  message("The 'kuzu' Python package is installed and available.")
  invisible(NULL)
}