# Tests for check_kuzu_installation function

test_that("check_kuzu_installation succeeds when all packages are installed", {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    reticulate::py_module_available("kuzu"),
    "kuzu python module not available for testing"
  )

  # Should print a success message and return invisibly
  expect_message(
    result <- check_kuzu_installation(),
    "The 'kuzu' Python package is installed and available."
  )
  expect_null(result)
})

test_that("check_kuzu_installation reports missing packages correctly", {
  testthat::skip_on_cran()

  # Mock py_module_available to simulate missing kuzu
  # We'll use local_mocked_bindings from testthat 3.0+
  local_mocked_bindings(
    py_module_available = function(pkg) {
      if (pkg == "kuzu") {
        return(FALSE)
      }
      return(TRUE)
    },
    .package = "reticulate"
  )

  # Should throw an error listing missing packages
  expect_error(
    check_kuzu_installation(),
    regexp = "kuzu.*not installed"
  )
})
