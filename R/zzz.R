kuzu <- NULL

.onLoad <- function(libname, pkgname) {
  # Use a delayed binding to avoid loading Python until it's needed
  kuzu <<- reticulate::import("kuzu", delay_load = TRUE)
}

.onAttach <- function(libname, pkgname) {
  # Check for kuzu and provide a helpful message if it's not found
  if (interactive()) {
    if (!reticulate::py_module_available("kuzu")) {
      msg <- paste(
        "The 'kuzu' Python package is not installed.",
        "\nPlease install it using: reticulate::py_install('kuzu', pip = TRUE)"
      )
      packageStartupMessage(msg)
    }
  }
}
