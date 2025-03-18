.onLoad <- function(libname, pkgname) {
  reticulate::py_require("kuzu")
  reticulate::py_require("pandas")

  kuzu <<- reticulate::import("kuzu", delay_load = TRUE)
  pd <<- reticulate::import("pandas", delay_load = TRUE)
}
