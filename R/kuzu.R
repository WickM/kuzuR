#' Initialize a Kuzu Database
#'
#' Establishes a connection to a Kuzu database. If the database does not exist
#' at the specified path, it will be created.
#'
#' @param path A string specifying the file path for the database. For an
#'   in-memory database, use `":memory:"`.
#' @return A Python object representing the Kuzu database instance.
#' @export
#' @examples
#' \dontrun{
#' # Create an in-memory database
#' db <- kuzu_database(":memory:")
#'
#' # Create or connect to an on-disk database
#' db_disk <- kuzu_database("my_kuzu_db")
#' }
kuzu_database <- function(path) {
  main <- reticulate::import_main()
  main$path <- path
  reticulate::py_run_string("import kuzu; db = kuzu.Database(path)", convert = FALSE)
  reticulate::py$db
}

#' Create a Connection to a Kuzu Database
#'
#' Creates a new connection to an existing Kuzu database instance. Multiple
#' connections can be established to the same database.
#'
#' @param db A Kuzu database object, as returned by `kuzu_database()`.
#' @return A Python object representing the connection to the Kuzu database.
#' @export
#' @examples
#' \dontrun{
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' }
kuzu_connection <- function(db) {
  main <- reticulate::import_main()
  main$db <- db
  reticulate::py_run_string("import kuzu; conn = kuzu.Connection(db)", convert = FALSE)
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
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#'
#' # Create a node table
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
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
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#'
#' # Convert the result to a data.frame
#' df <- as.data.frame(result)
#' print(df)
#' }
as.data.frame.kuzu.query_result.QueryResult <- function(x, ...) {
  if (!reticulate::py_module_available("pandas")) {
    stop("The 'pandas' Python package is required to convert results to a data.frame. ",
         "Please run `kuzuR::install_kuzu()`.", call. = FALSE)
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
#'   db <- kuzu_database(":memory:")
#'   conn <- kuzu_connection(db)
#'   kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
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
    stop("The 'tibble' package is required to use as_tibble(). Please install it.", call. = FALSE)
  }
  if (!reticulate::py_module_available("pandas")) {
    stop("The 'pandas' Python package is required to convert results to a tibble. ",
         "Please run `kuzuR::install_kuzu()`.", call. = FALSE)
  }
  tibble::as_tibble(x$get_as_df())
}

#' Retrieve All Rows from a Query Result
#'
#' Fetches all rows from a Kuzu query result and returns them as a list of lists.
#'
#' @param result A Kuzu query result object.
#' @return A list where each element is a list representing a row of results.
#' @export
#' @examples
#' \dontrun{
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' all_results <- kuzu_get_all(result)
#' }
kuzu_get_all <- function(result) {
  result$get_all()
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
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' first_row <- kuzu_get_n(result, 1)
#' }
kuzu_get_n <- function(result, n) {
  result$get_n(n)
}

#' Retrieve the Next Row from a Query Result
#'
#' Fetches the next available row from a Kuzu query result. This function can be
#' called repeatedly to iterate through results one by one.
#'
#' @param result A Kuzu query result object.
#' @return A list representing the next row, or `NULL` if no more rows are available.
#' @export
#' @examples
#' \dontrun{
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#' kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' row1 <- kuzu_get_next(result)
#' row2 <- kuzu_get_next(result)
#' }
kuzu_get_next <- function(result) {
  result$get_next()
}

#' Load Data from a Data Frame or Tibble into a Kuzu Table
#'
#' Efficiently copies data from an R `data.frame` or `tibble` into a specified
#' table in the Kuzu database.
#'
#' @param conn A Kuzu connection object.
#' @param table_name A string specifying the name of the destination table in Kuzu.
#' @param df A `data.frame` or `tibble` containing the data to load. Column
#'   names in the data frame should match the property names in the Kuzu table.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \dontrun{
#' db <- kuzu_database(":memory:")
#' conn <- kuzu_connection(db)
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#'
#' # Load from a data.frame
#' users_df <- data.frame(name = c("Carol", "Dan"), age = c(35, 40))
#' kuzu_copy_from_df(conn, "User", users_df)
#'
#' # Load from a tibble (if 'tibble' package is installed)
#' if (requireNamespace("tibble", quietly = TRUE)) {
#'   users_tbl <- tibble::tibble(name = c("Eve", "Frank"), age = c(45, 50))
#'   kuzu_copy_from_df(conn, "User", users_tbl)
#' }
#'
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' as.data.frame(result)
#' }
kuzu_copy_from_df <- function(conn, table_name, df) {
  main <- reticulate::import_main()
  main$conn <- conn
  main$df <- df
  query <- paste0("COPY ", table_name, " FROM df")
  main$query <- query
  # Explicitly import pandas to avoid potential importlib issues
  reticulate::py_run_string("import pandas as pd; conn.execute(query)", convert = FALSE)
  invisible(NULL)
}
