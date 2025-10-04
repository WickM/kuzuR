test_that("as.data.frame throws error if pandas is not available", {
  skip_if_not_installed("mockery")

  # Mock the python module check to simulate pandas not being available
  m <- mockery::mock(FALSE)
  mockery::stub(as.data.frame.kuzu.query_result.QueryResult, 'reticulate::py_module_available', m)

  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  # The table must exist for the query to succeed before the check
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, PRIMARY KEY (name))")
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name")

  expect_error(
    as.data.frame(result),
    "The 'pandas' Python package is required"
  )
  mockery::expect_called(m, 1)
  expect_equal(mockery::mock_args(m)[[1]][[1]], "pandas")

  rm(db, conn, result)
})

test_that("install_kuzu handles already installed packages", {
  skip_if_not_installed("mockery")

  m_check <- mockery::mock(TRUE, TRUE, TRUE)
  mockery::stub(install_kuzu, 'reticulate::py_module_available', m_check)

  expect_message(install_kuzu(), "already installed")
})

test_that("install_kuzu installs missing packages when user agrees", {
  skip_if_not_installed("mockery")

  m_check <- mockery::mock(FALSE, TRUE, FALSE) # kuzu and networkx are missing
  mockery::stub(install_kuzu, 'reticulate::py_module_available', m_check)

  m_ask <- mockery::mock(TRUE) # User says 'yes'
  mockery::stub(install_kuzu, 'utils::askYesNo', m_ask)

  m_install <- mockery::mock(NULL) # Mock the installation call
  mockery::stub(install_kuzu, 'reticulate::py_install', m_install)

  # Mock interactive() to return TRUE
  mockery::stub(install_kuzu, 'interactive', function() TRUE)

  expect_message(install_kuzu(), "The following required Python packages are not installed: kuzu, networkx")
  mockery::expect_called(m_install, 1)
  expect_equal(mockery::mock_args(m_install)[[1]][[1]], c("kuzu", "pandas", "networkx"))
})

test_that("install_kuzu respects user declining installation", {
  skip_if_not_installed("mockery")

  # Mock must provide a value for each call in sapply
  m_check <- mockery::mock(FALSE, cycle = TRUE)
  mockery::stub(install_kuzu, 'reticulate::py_module_available', m_check)

  m_ask <- mockery::mock(FALSE) # User says 'no'
  mockery::stub(install_kuzu, 'utils::askYesNo', m_ask)

  m_install <- mockery::mock(NULL)
  mockery::stub(install_kuzu, 'reticulate::py_install', m_install)

  # Mock interactive() to return TRUE
  mockery::stub(install_kuzu, 'interactive', function() TRUE)

  expect_message(install_kuzu(), "Installation cancelled by user.")
  mockery::expect_called(m_install, 0)
})

test_that("install_kuzu handles non-interactive sessions", {
  skip_if_not_installed("mockery")

  # Mock must provide a value for each call in sapply
  m_check <- mockery::mock(FALSE, cycle = TRUE)
  mockery::stub(install_kuzu, 'reticulate::py_module_available', m_check)

  # Mock interactive() to return FALSE
  mockery::stub(install_kuzu, 'interactive', function() FALSE)

  output <- capture.output(install_kuzu(), type = "message")
  expect_true(any(grepl("To install the required packages", output)))
})

# Test the logic of .onLoad without triggering the locked binding error
# We can do this by re-defining the function locally for the test
test_that(".onLoad logic provides message when packages are missing", {
  skip_if_not_installed("mockery")

  onLoad_logic <- function() {
    if (interactive()) {
      pkgs <- c("kuzu", "pandas")
      installed_status <- sapply(pkgs, reticulate::py_module_available)
      missing_pkgs <- names(installed_status[!installed_status])
      if (length(missing_pkgs) > 0) {
        msg <- paste("Required Python packages are not installed:", paste(missing_pkgs, collapse = ", "))
        packageStartupMessage(msg)
      }
    }
  }

  m_check <- mockery::mock(FALSE, FALSE) # Neither kuzu nor pandas is available
  mockery::stub(onLoad_logic, 'reticulate::py_module_available', m_check)
  mockery::stub(onLoad_logic, 'interactive', function() TRUE)

  expect_message(onLoad_logic(), "Required Python packages are not installed: kuzu, pandas")
})

test_that(".onLoad logic is silent when packages are installed", {
  skip_if_not_installed("mockery")

  onLoad_logic <- function() {
    if (interactive()) {
      pkgs <- c("kuzu", "pandas")
      installed_status <- sapply(pkgs, reticulate::py_module_available)
      missing_pkgs <- names(installed_status[!installed_status])
      if (length(missing_pkgs) > 0) {
        msg <- paste("Required Python packages are not installed:", paste(missing_pkgs, collapse = ", "))
        packageStartupMessage(msg)
      }
    }
  }

  m_check <- mockery::mock(TRUE, TRUE)
  mockery::stub(onLoad_logic, 'reticulate::py_module_available', m_check)
  mockery::stub(onLoad_logic, 'interactive', function() TRUE)

  expect_silent(onLoad_logic())
})

test_that("as_tibble throws error if tibble is not available", {
  skip_if_not_installed("mockery")

  # Mock the namespace check to simulate tibble not being available
  m_req <- mockery::mock(FALSE)
  mockery::stub(as_tibble.kuzu.query_result.QueryResult, 'requireNamespace', m_req)

  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, PRIMARY KEY (name))")
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name")

  expect_error(
    tibble::as_tibble(result),
    "The 'tibble' package is required"
  )
  mockery::expect_called(m_req, 1)

  rm(db, conn, result)
})

test_that("as_tibble throws error if pandas is not available but tibble is", {
  skip_if_not_installed("mockery")

  # Mock the python module check to simulate pandas not being available
  m_py <- mockery::mock(FALSE)
  mockery::stub(as_tibble.kuzu.query_result.QueryResult, 'reticulate::py_module_available', m_py)

  # Ensure the tibble check passes
  m_req <- mockery::mock(TRUE)
  mockery::stub(as_tibble.kuzu.query_result.QueryResult, 'requireNamespace', m_req)

  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, PRIMARY KEY (name))")
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name")

  expect_error(
    tibble::as_tibble(result),
    "The 'pandas' Python package is required"
  )
  mockery::expect_called(m_py, 1)
  expect_equal(mockery::mock_args(m_py)[[1]][[1]], "pandas")

  rm(db, conn, result)
})
