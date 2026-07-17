kuzu <- NULL

.onLoad <- function(libname, pkgname) {
  # Use a delayed binding to avoid loading Python until it's needed
  kuzu <<- reticulate::import("kuzu", delay_load = TRUE)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "NOTE: 'kuzuR' is deprecated and no longer maintained.\n",
    "The Kuzu graph database and its Python client library are no longer\n",
    "maintained and no longer available. This package cannot function and\n",
    "will not receive further updates, bug fixes, or security patches."
  )
  
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
