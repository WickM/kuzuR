# Data Loading Functions

#' Load Data from a Data Frame or Tibble into a Kuzu Table
#'
#' Efficiently copies data from an R `data.frame` or `tibble` into a specified
#' table in the Kuzu database.
#'
#' When loading into a relationship table, Kuzu assumes the first two columns in the file are:
#' FROM Node Column: The primary key of the FROM nodes.
#' TO Node Column: The primary key of the TO nodes.
#'
#' @param conn A Kuzu connection object.
#' @param df A `data.frame` or `tibble` containing the data to load. Column
#'   names in the data frame should match the property names in the Kuzu table.
#' @param table_name A string specifying the name of the destination table in Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \dontrun{
#' conn <- kuzu_connection(":memory:")
#' kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
#' kuzu_execute(conn, "CREATE REL TABLE Knows(FROM Person TO Person)") # Corrected 'con' to 'conn'
#' #Load from a data.frame
#' users_df <- data.frame(name = c("Carol", "Dan"), age = c(35, 40))
#' kuzu_copy_from_df(conn, users_df, "User") # Corrected argument order
#'
#'#Load from a tibble
#' knows <- tibble(from_person = c("Alice", "Bob"), to_person = c("Bob", "Carol"))
#' kuzu_copy_from_df(conn, knows, "knows") # Corrected argument order
#'
#' result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#' result_rel <- kuzu_execute(conn, "MATCH (a:Person)-[k:Knows]->(b:Person) RETURN a.name,b.name") # Corrected 'con' to 'conn'
#' }
#' @seealso \href{https://docs.kuzudb.com/import/copy-from-dataframe/}{Kuzu Copy from DataFrame}
kuzu_copy_from_df <- function(conn, df, table_name) {
  main <- reticulate::import_main()
  main$conn <- conn
  main$df_to_copy <- df

  query <- paste0("COPY ", table_name, " FROM df_to_copy")
  main$query <- query
  reticulate::py_run_string("conn.execute(query)", convert = FALSE)

  invisible(NULL)
}

#Copyfromfile internal Function
# This is an internal helper function and not intended for direct user use.
# It handles the core logic of copying data from a file path.
kuzu_copy_from_file <- function(conn, file_path, table_name, optionalParameter = NULL) {
    main <- reticulate::import_main()
    main$conn <- conn
    file_path <- normalizePath(file_path, mustWork = FALSE)
    query <- paste0("COPY ", table_name, " FROM '", file_path, "'")
    if (!is.null(optionalParameter)) {
        opts <- paste(names(optionalParameter), "=", unlist(optionalParameter), collapse = ", ")
        query <- paste0(query, " (", opts, ")")
    }
    main$query <- query
    reticulate::py_run_string("conn.execute(query)", convert = FALSE)
    invisible(NULL)
}

#' Load Data from a CSV File into a Kuzu Table
#'
#' Loads data from a CSV file into a specified table in the Kuzu database.
#'
#' @param conn A Kuzu connection object.
#' @param file_path A string specifying the path to the CSV file.
#' @param table_name A string specifying the name of the destination table in Kuzu.
#' @param optionalcsvParameter An optional parameter for CSV-specific configurations (e.g., delimiter, header).
#'   Refer to Kuzu documentation for available options.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @seealso \href{https://docs.kuzudb.com/import/csv/}{Kuzu CSV Import}
kuzu_copy_from_csv <- function(conn, file_path, table_name, optionalcsvParameter=NULL) {

  # Note: The 'optionalcsvParameter' is passed to kuzu_copy_from_file but not directly used in its current query construction.
  # Further logic might be needed here to translate optionalcsvParameter into Kuzu COPY options if supported.
  kuzu_copy_from_file(conn, file_path =  file_path, table_name = table_name, optionalParameter = optionalcsvParameter)

}

#' Load Data from a JSON File into a Kuzu Table
#'
#' Loads data from a JSON file into a specified table in the Kuzu database.
#' This function also ensures the JSON extension is loaded and available.
#'
#' @param conn A Kuzu connection object.
#' @param file_path A string specifying the path to the JSON file.
#' @param table_name A string specifying the name of the destination table in Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @seealso \href{https://docs.kuzudb.com/import/copy-from-json/}{Kuzu JSON Import}, \href{https://docs.kuzudb.com/extensions/json/}{Kuzu JSON Extension}
kuzu_copy_from_json <- function(conn, file_path, table_name) {
    # Ensure the JSON extension is installed and loaded
    tryCatch({
        kuzu_execute(conn, query = "INSTALL json;LOAD json;")
    }, error = function(e) {
        warning("Could not install or load JSON extension. Please check your internet connection and Kuzu setup.")
    })
    # Use the internal copy function to load data from the JSON file
    kuzu_copy_from_file(conn, file_path = file_path, table_name = table_name)
}

#' Load Data from a Parquet File into a Kuzu Table
#'
#' Loads data from a Parquet file into a specified table in the Kuzu database.
#'
#' @param conn A Kuzu connection object.
#' @param file_path A string specifying the path to the Parquet file.
#' @param table_name A string specifying the name of the destination table in Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @seealso \href{https://docs.kuzudb.com/import/parquet/}{Kuzu Parquet Import}
kuzu_copy_from_parquet <- function(conn, file_path, table_name) {
    # Use the internal copy function to load data from the Parquet file
    kuzu_copy_from_file(conn, file_path =  file_path, table_name = table_name)
}

#' Merge Data from a Data Frame into Kuzu using a Merge Query
#'
#' This function is intended for merging data from an R `data.frame` into Kuzu
#' using a specified merge query. It leverages Python's reticulate to interact
#' with Kuzu's Python API.
#'
#' @param conn A Kuzu connection object.
#' @param df A `data.frame` or `tibble` containing the data to merge.
#' @param merge_query A string representing the Kuzu query for merging data.
#' @return This function is called for its side effect of merging data and does
#'   not return a value.
#' @export
#' @examples
#' \dontrun{
#' my_data <- data.frame(
#'    name = c("Alice", "Bob"),
#'    item = c("Book", "Pen"),
#'    current_city = c("New York", "London")
#'  )
#' 
#'  merge_statement <- "MERGE (p:Person {name: df.name})
#'  MERGE (i:Item {name: df.item})
#'  MERGE (p)-[:PURCHASED]->(i)
#'  ON MATCH SET p.current_city = df.current_city
#'  ON CREATE SET p.current_city = df.current_city"
#' 
#'  kuzu_merge_df(conn, my_data, merge_statement)
#' 
#'  # Example with a different merge query structure:
#'  my_data_2 <- data.frame(
#'    person_name = c("Charlie"),
#'    purchased_item = c("Laptop"),
#'    city = c("Paris")
#'  )
#' #
#'  merge_statement_2 <- "MERGE (p:Person {name: person_name})
#'  MERGE (i:Item {name: purchased_item})
#'  MERGE (p)-[:PURCHASED]->(i)
#'  ON MATCH SET p.current_city = city
#'  ON CREATE SET p.current_city = city"
#' 
#'  kuzu_merge_df(conn, my_data_2, merge_statement_2)
#'  }
#' @seealso \href{https://docs.kuzudb.com/import/copy-from-dataframe/}{Kuzu Copy from DataFrame}
kuzu_merge_df <- function(conn, df, merge_query) {
    main <- reticulate::import_main()
    main$conn <- conn
    main$df <- df
    query <- paste0("LOAD FROM df ", merge_query)
    main$query <- query
    reticulate::py_run_string("conn.execute(query)", convert = FALSE)
    invisible(NULL)
}
