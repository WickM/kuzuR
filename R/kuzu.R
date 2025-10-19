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
#' # Create an in-memory database and connection
#' conn <- kuzu_connection(":memory:")
#'
#' # Create or connect to an on-disk database
#' \dontrun{
#' conn_disk <- kuzu_connection("my_kuzu_db")
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
#' \dontrun{
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
#' \dontrun{
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
  if (!reticulate::py_module_available("pandas")) {
    stop(
      "The 'pandas' Python package is required to convert results to a ",
      "data.frame. ",
      "Please run `kuzuR::install_kuzu()`.",
      call. = FALSE
    )
  }
  x$get_as_df()
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
#' \dontrun{
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
    stop(
      "The 'tibble' package is required to use as_tibble(). Please install it.",
      call. = FALSE
    )
  }
  if (!reticulate::py_module_available("pandas")) {
    stop(
      "The 'pandas' Python package is required to convert results to a ",
      "tibble. ",
      "Please run `kuzuR::install_kuzu()`.",
      call. = FALSE
    )
  }
  tibble::as_tibble(x$get_as_df())
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
#' \dontrun{
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
#' \dontrun{
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
#' \dontrun{
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

#TODO UDF

#' Get Column Data Types from a Query Result
#'
#' Retrieves the data types of the columns in a Kuzu query result.
#'
#' @param result A Kuzu query result object.
#' @return A character vector of column data types.
#' @export
#' @examples
#' \dontrun{
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
#' \dontrun{
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
#' \dontrun{
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

#TODO Create helper function to deal with DEZIMAL and UUID
