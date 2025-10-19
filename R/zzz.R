kuzu <- NULL
pandas <- NULL
networkx <- NULL

.onLoad <- function(libname, pkgname) {
  # Declare Python packages needed by your package for CRAN compliance
  reticulate::py_require("kuzu")
  reticulate::py_require("pandas")
  reticulate::py_require("networkx")

  # Use a delayed binding to avoid loading Python until it's needed
  kuzu <<- reticulate::import("kuzu", delay_load = TRUE)
  pandas <<- reticulate::import("pandas", delay_load = TRUE)
  networkx <<- reticulate::import("networkx", delay_load = TRUE)
}

.onAttach <- function(libname, pkgname) {
  # Check for kuzu and pandas and provide a helpful message if they're not found
  if (interactive()) {
    pkgs <- c("kuzu", "pandas")
    installed_status <- sapply(pkgs, reticulate::py_module_available)
    missing_pkgs <- names(installed_status[!installed_status])

    if (length(missing_pkgs) > 0) {
      msg <- paste(
        "Required Python packages are not installed:",
        paste(missing_pkgs, collapse = ", "),
        "\nPlease run `kuzuR::install_kuzu()` to install them."
      )
      packageStartupMessage(msg)
    }
  }
}
