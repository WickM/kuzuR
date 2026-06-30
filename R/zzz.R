kuzu <- NULL

.onLoad <- function(libname, pkgname) {
  # Use a delayed binding to avoid loading Python until it's needed
  kuzu <<- reticulate::import("kuzu", delay_load = TRUE)
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "NOTE: The Python package 'kuzu' has been archived. ",
    "As a result, 'kuzuR' can no longer be used and will be archived as well. ",
    "Please use 'lbugr' instead."
  )

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
