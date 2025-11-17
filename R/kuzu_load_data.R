# Data Loading Functions

#' Load Data from a Data Frame or Tibble into a Kuzu Table
#'
#' Efficiently copies data from an R `data.frame` or `tibble` into a specified
#' table in the Kuzu database.
#'
#' When loading into a relationship table, Kuzu assumes the first two columns 
#' in the file are:
#' FROM Node Column: The primary key of the FROM nodes.
#' TO Node Column: The primary key of the TO nodes.
#'
#' @param conn A Kuzu connection object.
#' @param df A `data.frame` or `tibble` containing the data to load. Column
#'   names in the data frame should match the property names in the Kuzu table.
#' @param table_name A string specifying the name of the destination table in 
#' Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \donttest{
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, 
#'   PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE REL TABLE Knows(FROM User TO User)")
#'
#'   # Load from a data.frame
#'   users_df <- data.frame(name = c("Carol", "Dan"), age = c(35, 40))
#'   kuzu_copy_from_df(conn, users_df, "User")
#'
#'   # Load from a tibble (requires pre-existing nodes)
#'   kuzu_execute(conn, "CREATE (u:User {name: 'Alice'}), (v:User {name: 'Bob'})")
#'   knows_df <- data.frame(from_person = c("Alice", "Bob"), 
#'   to_person = c("Bob", "Carol"))
#'   kuzu_copy_from_df(conn, knows_df, "Knows")
#'
#'   result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#'   print(as.data.frame(result))
#'
#'   result_rel <- kuzu_execute(conn, "MATCH (a:User)-[k:Knows]->(b:User) 
#'   RETURN a.name, b.name")
#'   print(as.data.frame(result_rel))
#' }
#' @seealso \href{https://kuzudb.github.io/docs/import/copy-from-dataframe/}{Kuzu Copy from DataFrame}
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
kuzu_copy_from_file <- function(
  conn,
  file_path,
  table_name,
  optional_parameter = NULL
) {
  main <- reticulate::import_main()
  main$conn <- conn

  # Replace backslashes with forward slashes for compatibility
  file_path <- gsub("\\\\", "/", file_path)

  query <- paste0("COPY ", table_name, " FROM '", file_path, "'")

  if (!is.null(optional_parameter)) {
    opts <- paste(
      names(optional_parameter),
      "=",
      unlist(optional_parameter),
      collapse = ", "
    )
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
#' @param table_name A string specifying the name of the destination table in 
#' Kuzu.
#' @param optional_csv_parameter An optional parameter for CSV-specific 
#' configurations (e.g., delimiter, header).
#'   Refer to Kuzu documentation for available options.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \donttest{
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE City(name STRING, population INT64, 
#'   PRIMARY KEY (name))")
#'
#'   # Create a temporary CSV file
#'   csv_file <- tempfile(fileext = ".csv")
#'   write.csv(data.frame(name = c("Berlin", "London"), 
#'   population = c(3645000, 8982000)),
#'             csv_file, row.names = FALSE)
#'
#'   # Load data from CSV
#'   kuzu_copy_from_csv(conn, csv_file, "City")
#'
#'   # Verify the data
#'   result <- kuzu_execute(conn, "MATCH (c:City) RETURN c.name, c.population")
#'   print(as.data.frame(result))
#'
#'   # Clean up the temporary file
#'   unlink(csv_file)
#' }
#' @seealso \href{https://kuzudb.github.io/docs/import/csv/}{Kuzu CSV Import}
kuzu_copy_from_csv <- function(
  conn,
  file_path,
  table_name,
  optional_csv_parameter = NULL
) {
  #TODO Note: The 'optional_csv_parameter' is passed to kuzu_copy_from_file but 
  # not directly used in its current query construction.
  # Further logic might be needed here to translate optional_csv_parameter into 
  # Kuzu COPY options if supported.
  kuzu_copy_from_file(
    conn,
    file_path = file_path,
    table_name = table_name,
    optional_parameter = optional_csv_parameter
  )
}

#' Load Data from a JSON File into a Kuzu Table
#'
#' Loads data from a JSON file into a specified table in the Kuzu database.
#' This function also ensures the JSON extension is loaded and available.
#'
#' @param conn A Kuzu connection object.
#' @param file_path A string specifying the path to the JSON file.
#' @param table_name A string specifying the name of the destination table in 
#' Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \donttest{
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Product(id INT64, name STRING, 
#'   PRIMARY KEY (id))")
#'
#'   # Create a temporary JSON file
#'   json_file <- tempfile(fileext = ".json")
#'   json_data <- '[{"id": 1, "name": "Laptop"}, {"id": 2, "name": "Mouse"}]'
#'   writeLines(json_data, json_file)
#'
#'   # Load data from JSON
#'   kuzu_copy_from_json(conn, json_file, "Product")
#'
#'   # Verify the data
#'   result <- kuzu_execute(conn, "MATCH (p:Product) RETURN p.id, p.name")
#'   print(as.data.frame(result))
#'
#'   # Clean up the temporary file
#'   unlink(json_file)
#' }
#' @seealso \href{https://kuzudb.github.io/docs/import/copy-from-json/}{Kuzu JSON Import}, \href{https://kuzudb.github.io/docs/extensions/json/}{Kuzu JSON Extension}
kuzu_copy_from_json <- function(conn, file_path, table_name) {
  # Ensure the JSON extension is installed and loaded
  tryCatch(
    {
      kuzu_execute(conn, query = "INSTALL json;LOAD json;")
    },
    error = function(e) {
      warning(
        paste("Could not install or load JSON extension. Please check your",
              "internet connection and Kuzu setup.")
      )
    }
  )
  # Use the internal copy function to load data from the JSON file
  kuzu_copy_from_file(conn, file_path = file_path, table_name = table_name)
}

#' Load Data from a Parquet File into a Kuzu Table
#'
#' Loads data from a Parquet file into a specified table in the Kuzu database.
#'
#' @param conn A Kuzu connection object.
#' @param file_path A string specifying the path to the Parquet file.
#' @param table_name A string specifying the name of the destination table in 
#' Kuzu.
#' @return This function is called for its side effect of loading data and does
#'   not return a value.
#' @export
#' @examples
#' \donttest{
#'   if (requireNamespace("arrow", quietly = TRUE)) {
#'     conn <- kuzu_connection(":memory:")
#'     kuzu_execute(conn, "CREATE NODE TABLE Country(name STRING, code STRING, 
#'     PRIMARY KEY (name))")
#'
#'     # Create a temporary Parquet file
#'     parquet_file <- tempfile(fileext = ".parquet")
#'     country_df <- data.frame(name = c("USA", "Canada"), code = c("US", "CA"))
#'     arrow::write_parquet(country_df, parquet_file)
#'
#'     # Load data from Parquet
#'     kuzu_copy_from_parquet(conn, parquet_file, "Country")
#'
#'     # Verify the data
#'     result <- kuzu_execute(conn, "MATCH (c:Country) RETURN c.name, c.code")
#'     print(as.data.frame(result))
#'
#'     # Clean up the temporary file
#'     unlink(parquet_file)
#'   }
#' }
#' @seealso \href{https://kuzudb.github.io/docs/import/parquet/}{Kuzu Parquet Import}
kuzu_copy_from_parquet <- function(conn, file_path, table_name) {
  # Use the internal copy function to load data from the Parquet file
  kuzu_copy_from_file(conn, file_path = file_path, table_name = table_name)
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
#'  # Note: 'conn' would need to be a valid Kuzu connection object
#'  # and the schema (Person, Item, PURCHASED tables) would need to be created
#'  # before running this example.
#'  # kuzu_merge_df(conn, my_data, merge_statement)
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
#'  # kuzu_merge_df(conn, my_data_2, merge_statement_2)
#'  }
#' @seealso \href{https://kuzudb.github.io/docs/import/copy-from-dataframe/}{Kuzu Copy from DataFrame}
kuzu_merge_df <- function(conn, df, merge_query) {
  main <- reticulate::import_main()
  main$conn <- conn
  main$df <- df
  query <- paste0("LOAD FROM df ", merge_query)
  main$query <- query
  reticulate::py_run_string("conn.execute(query)", convert = FALSE)
  invisible(NULL)
}
