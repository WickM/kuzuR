# Create a Connection to a Kuzu Database

Establishes a connection to a Kuzu database. If the database does not
exist at the specified path, it will be created. This function combines
the database initialization and connection steps into a single call.

## Usage

``` r
kuzu_connection(path)
```

## Arguments

- path:

  A string specifying the file path for the database. For an in-memory
  database, use `":memory:"`.

## Value

A Python object representing the connection to the Kuzu database.

## Examples

``` r
# \donttest{
# Create an in-memory database and connection
conn <- kuzu_connection(":memory:")
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.

# Create or connect to an on-disk database
temp_db_dir <- file.path(tempdir(), "kuzu_disk_example_db")
db_path <- file.path(temp_db_dir, "kuzu_db")
dir.create(temp_db_dir, recursive = TRUE, showWarnings = FALSE)

# Establish connection
conn_disk <- kuzu_connection(db_path)
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.

# Ensure the database is shut down and removed on exit
on.exit({
  # Access the 'db' object from the reticulate main module
  main <- reticulate::import_main()
  if (!is.null(main$db)) {
    main$db$shutdown()
  }
  unlink(temp_db_dir, recursive = TRUE)
})
#> Error in py_get_attr(x, name, FALSE): AttributeError: module '__main__' has no attribute 'db'
#> Run `reticulate::py_last_error()` for details.
# }
```
