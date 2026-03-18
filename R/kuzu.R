#' Create a Connection to a Kuzu Database
#'
#' Establishes a connection to a Kuzu database. If the database does not exist
#' at the specified path, it will be created. This function combines the
#' database initialization and connection steps into a single call.
#'
#' @param path A string specifying the file path for the database. For an
#'   in-memory database, use `":memory:"`.
#' @return A Python object representing the connection to the Kuzu database.
#' @export
#' @examples
#' \donttest{
#' # Create an in-memory database and connection
#' conn <- kuzu_connection(":memory:")
#'
#' # Create or connect to an on-disk database
#' temp_db_dir <- file.path(tempdir(), "kuzu_disk_example_db")
#' db_path <- file.path(temp_db_dir, "kuzu_db")
#' dir.create(temp_db_dir, recursive = TRUE, showWarnings = FALSE)
#'
#' # Establish connection
#' conn_disk <- kuzu_connection(db_path)
#'
#' # Ensure the database is shut down and removed on exit
#' on.exit({
#'   # Access the 'db' object from the reticulate main module
#'   main <- reticulate::import_main()
#'   if (!is.null(main$db)) {
#'     main$db$shutdown()
#'   }
#'   unlink(temp_db_dir, recursive = TRUE)
#' })
#' }
kuzu_connection <- function(path) {
  main <- reticulate::import_main()
  main$path <- path
  reticulate::py_run_string(
    "import kuzu; db = kuzu.Database(path); conn = kuzu.Connection(db)",
    convert = FALSE
  )
  reticulate::py$conn
}

#' Execute a Cypher Query
#'
#' Submits a Cypher query to the Kuzu database for execution. This function
#' is used for all database operations, including schema definition (DDL),
#' data manipulation (DML), and querying (MATCH).
#'
#' @param conn A Kuzu connection object, as returned by `kuzu_connection()`.
#' @param query A string containing the Cypher query to be executed.
#' @return A Python object representing the query result.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#'
#' # Create a node table
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#'
#' # Insert data
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#'
#' # Query data
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' }
kuzu_execute <- function(conn, query) {
  main <- reticulate::import_main()
  main$conn <- conn
  main$query <- query
  reticulate::py_run_string("result = conn.execute(query)", convert = FALSE)
  reticulate::py$result
}

#' Convert a Kuzu Query Result to a Data Frame
#'
#' Provides an S3 method to seamlessly convert a Kuzu query result object into a
#' standard R `data.frame`.
#'
#' @param x A Kuzu query result object.
#' @param ... Additional arguments passed to `as.data.frame`.
#' @return An R `data.frame` containing the query results.
#' @method as.data.frame kuzu.query_result.QueryResult
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#'
#' # Convert the result to a data.frame
#' df <- as.data.frame(result)
#' print(df)
#' }
as.data.frame.kuzu.query_result.QueryResult <- function(x, ...) {
  col_names <- x$get_column_names()
  all_rows_values <- x$get_all()

  # Convert list of lists to named lists, converting Python objects to R values
  df_list <- lapply(all_rows_values, function(row) {
    converted_row <- lapply(row, convert_python_to_r)
    stats::setNames(converted_row, col_names)
  })

  # Handle empty results
  if (length(df_list) == 0) {
    as.data.frame(setNames(list(), col_names), stringsAsFactors = FALSE)
  } else {
    # Convert to data.frame by rbinding named lists
    do.call(
      rbind,
      lapply(df_list, function(x) {
        as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
      })
    )
  }
}

#' Convert a Kuzu Query Result to a Tibble
#'
#' Provides an S3 method to convert a Kuzu query result object into a
#' `tibble`. This requires the `tibble` package to be installed.
#'
#' @param x A Kuzu query result object.
#' @param ... Additional arguments passed to `as_tibble`.
#' @return A `tibble` containing the query results.
#' @importFrom tibble as_tibble
#' @method as_tibble kuzu.query_result.QueryResult
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("tibble", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#'   PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#'   result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#'
#'   # Convert the result to a tibble
#'   tbl <- tibble::as_tibble(result)
#'   print(tbl)
#' }
#' }
as_tibble.kuzu.query_result.QueryResult <- function(x, ...) {
  if (!requireNamespace("tibble", quietly = TRUE)) {
    #TODO not nescesary tibble is a dependency
    stop(
      "The 'tibble' package is required to use as_tibble(). Please install it.",
      call. = FALSE
    )
  }
  #TODO whix not use the data frame function and convert the data frame to tibble
  #-> reduces code duplication
  col_names <- x$get_column_names()
  all_rows_values <- x$get_all()

  # Convert list of lists to named lists, converting Python objects to R values
  df_list <- lapply(all_rows_values, function(row) {
    converted_row <- lapply(row, convert_python_to_r)
    stats::setNames(converted_row, col_names)
  })

  # Handle empty results
  if (length(df_list) == 0) {
    tibble::as_tibble(setNames(list(), col_names))
  } else {
    # Convert to tibble by rbinding named lists
    tibble::as_tibble(do.call(
      rbind,
      lapply(df_list, function(x) {
        as.data.frame(x, stringsAsFactors = FALSE, check.names = FALSE)
      })
    ))
  }
}

#' Retrieve All Rows from a Query Result
#'
#' Fetches all rows from a Kuzu query result and returns them as a list of
#' lists.
#'
#' @param result A Kuzu query result object.
#' @return A list where each element is a list representing a row of results.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' all_results <- kuzu_get_all(result)
#' }
kuzu_get_all <- function(result) {
  col_names <- result$get_column_names()
  all_rows_values <- result$get_all()
  lapply(all_rows_values, function(row) {
    stats::setNames(row, col_names)
  })
}

#' Retrieve the First N Rows from a Query Result
#'
#' Fetches the first `n` rows from a Kuzu query result.
#'
#' @param result A Kuzu query result object.
#' @param n The number of rows to retrieve.
#' @return A list of the first `n` rows.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' first_row <- kuzu_get_n(result, 1)
#' }
kuzu_get_n <- function(result, n) {
  col_names <- result$get_column_names()
  # Convert n to integer for reticulate
  n_rows_values <- result$get_n(as.integer(n))
  lapply(n_rows_values, function(row) {
    stats::setNames(row, col_names)
  })
}

#' Retrieve the Next Row from a Query Result
#'
#' Fetches the next available row from a Kuzu query result. This function can be
#' called repeatedly to iterate through results one by one.
#'
#' @param result A Kuzu query result object.
#' @return A list representing the next row, or `NULL` if no more rows are
#' available.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' row1 <- kuzu_get_next(result)
#' row2 <- kuzu_get_next(result)
#' }
kuzu_get_next <- function(result) {
  if (!result$has_next()) {
    return(NULL)
  }
  col_names <- result$get_column_names()
  row_values <- result$get_next()
  stats::setNames(row_values, col_names)
}

#' Get Column Data Types from a Query Result
#'
#' Retrieves the data types of the columns in a Kuzu query result.
#'
#' @param result A Kuzu query result object.
#' @return A character vector of column data types.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' kuzu_get_column_data_types(result)
#' }
kuzu_get_column_data_types <- function(result) {
  result$get_column_data_types()
}

#' Get Column Names from a Query Result
#'
#' Retrieves the names of the columns in a Kuzu query result.
#'
#' @param result A Kuzu query result object.
#' @return A character vector of column names.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' kuzu_get_column_names(result)
#' }
kuzu_get_column_names <- function(result) {
  result$get_column_names()
}

#' Get Schema from a Query Result
#'
#' Retrieves the schema (column names and data types) of a Kuzu query result.
#'
#' @param result A Kuzu query result object.
#' @return A named list where names are column names and values are data types.
#' @export
#' @examples
#' \donttest{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
#' PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' kuzu_get_schema(result)
#' }
kuzu_get_schema <- function(result) {
  result$get_schema()
}

#' Convert Python Objects to R Values
#'
#' Internal helper function to convert Python objects (like Decimal, UUID, nodes) to R values
#'
#' @param x A value that might be a Python object
#' @return An R-compatible value
#' @keywords internal
convert_python_to_r <- function(x) {
  # Handle NULL values from Python - convert to NA
  if (is.null(x)) {
    return(NA)
  }
  if (inherits(x, "python.builtin.object")) {
    # Handle Python Decimal by converting via string to avoid precision loss
    if (inherits(x, "decimal.Decimal")) {
      return(as.numeric(as.character(reticulate::py_str(x))))
    }
    # Handle UUID as string
    if (inherits(x, "uuid.UUID")) {
      return(reticulate::py_str(x))
    }
    # NOTE: We intentionally do NOT convert Node/Rel objects to strings here.
    # They will be automatically converted by reticulate to R lists with
    # their properties (_id, _label, _src, _dst, etc.) which is needed for
    # graph conversion via as_igraph() and as_tidygraph().
    # Do NOT add special handling for kuzu.common.Node or kuzu.common.Rel.
    
    # Handle other Python objects by converting to string
    return(reticulate::py_str(x))
  }
  # Handle nested lists (e.g., from node/relationship objects that are already converted)
  if (is.list(x)) {
    # Recursively convert each element in the list
    return(lapply(x, convert_python_to_r))
  }
  x
}

