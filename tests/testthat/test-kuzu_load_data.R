skip_if_not(reticulate::py_available(), "Python not available for testing")

test_that("kuzu_copy_from_df works for node and rel tables", {
  conn <- kuzu_connection(":memory:")

  # Test Node Table
  kuzu_execute(
    conn,
    "CREATE NODE TABLE Product(id INT64, name STRING, PRIMARY KEY (id))"
  )
  products_df <- data.frame(id = c(1, 2), name = c("Laptop", "Mouse"))
  kuzu_copy_from_df(conn, products_df, "Product")
  result <- kuzu_execute(
    conn,
    "MATCH (p:Product) RETURN p.id, p.name ORDER BY p.id"
  )
  df_check <- as.data.frame(result)
  expect_equal(nrow(df_check), 2)
  expect_equal(df_check$p.id, c(1, 2))

  # Test Rel Table
  kuzu_execute(
    conn,
    "CREATE NODE TABLE Person(name STRING, PRIMARY KEY (name))"
  )
  kuzu_execute(
    conn,
    "CREATE REL TABLE Follows(FROM Person TO Person, since INT64)"
  )
  persons_df <- data.frame(name = c("Alice", "Bob"))
  kuzu_copy_from_df(conn, persons_df, "Person")

  follows_df <- data.frame(
    from_person = "Alice",
    to_person = "Bob",
    since = 2023
  )
  kuzu_copy_from_df(conn, follows_df, "Follows")

  result_rel <- kuzu_execute(
    conn,
    "MATCH (a:Person)-[f:Follows]->(b:Person) RETURN a.name, b.name, f.since"
  )
  df_rel_check <- as.data.frame(result_rel)
  expect_equal(nrow(df_rel_check), 1)
  expect_equal(df_rel_check$a.name, "Alice")
  expect_equal(df_rel_check$b.name, "Bob")
  expect_equal(df_rel_check$f.since, 2023)

  # Test error if primary key is missing
  bad_follows_df <- data.frame(
    start_person = "xxx",
    end_person = "Bob",
    since = 2023
  )

  expect_error(
    kuzu_copy_from_df(conn, bad_follows_df, "Follows"),
  )
})

test_that("kuzu_copy_from_df handles various data types", {
  conn <- kuzu_connection(":memory:")

  # Create table with various Kuzu data types
  kuzu_execute(
    conn,
    "CREATE NODE TABLE MixedTypes(
    id INT64,
    name STRING,
    is_active BOOL,
    value FLOAT,
    amount DOUBLE,
    event_date DATE,
    timestamp TIMESTAMP,
    price INT64,
    price2 DECIMAL,
    int8_col INT8,
    int16_col INT16,
    int32_col INT32,
    int128_col INT128,
    uint8_col UINT8,
    uint16_col UINT16,
    serial_col SERIAL,
    PRIMARY KEY (id)
  )"
  )

  # Create a data frame with corresponding R data types
  mixed_df <- data.frame(
    id = c(1L, 2L),
    name = c("Test Item", "Another Item"),
    is_active = c(TRUE, FALSE),
    value = c(1.23, 4.56),
    amount = c(10.12345, 67.89012),
    event_date = as.Date(c("2023-01-15", "2023-02-20")),
    timestamp = as.POSIXct(c("2023-01-15 10:30:00", "2023-02-20 14:45:00"), tz = "UTC"),
    price = c(99.99, 123.45),
    price2 = c(99.99, 123.45),
    int8_col = c(1L, -128L),
    int16_col = c(100L, -1000L),
    int32_col = c(10000L, -50000L),
    int128_col = c(1.234567890123456789e18, -9.876543210987654321e18),
    uint8_col = c(0L, 255L),
    uint16_col = c(0L, 65535L),
    stringsAsFactors = FALSE # Ensure strings are not converted to factors
  )

  kuzu_copy_from_df(conn, mixed_df, "MixedTypes")

  # Query and verify data
  result <- kuzu_execute(
    conn,
    paste("MATCH (m:MixedTypes) RETURN m.id, m.name, m.is_active, m.value,",
          "m.amount, m.event_date, m.timestamp, m.price, m.price2,m.int8_col,",
          "m.int16_col, m.int32_col, m.int128_col, m.uint8_col, m.uint16_col,",
          "m.serial_col ORDER BY m.id")
  )
  df_check <- as.data.frame(result)

  expect_equal(nrow(df_check), 2)
  expect_equal(df_check$m.id, c(1L, 2L))
  expect_equal(df_check$m.name, c("Test Item", "Another Item"))
  expect_equal(df_check$m.is_active, c(TRUE, FALSE))
  expect_equal(df_check$m.value, c(1.23, 4.56))
  expect_equal(df_check$m.amount, c(10.12345, 67.89012))
  expect_equal(
    substr(as.character(df_check$m.event_date), 1, 10),
    c("2023-01-15", "2023-02-20")
  )
  # Format both actual and expected to UTC strings for a robust comparison
  expected_timestamps_df <- as.POSIXct(c("2023-01-15 10:30:00", "2023-02-20 14:45:00"), tz = "UTC")
  expect_equal(
    format(df_check$m.timestamp, tz = "UTC", format = "%Y-%m-%d %H:%M:%S"),
    format(expected_timestamps_df, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")
  )
  expect_equal(df_check$m.price, c(100, 123))
  expect_equal(df_check$m.int8_col, c(1L, -128L))
  expect_equal(df_check$m.int16_col, c(100L, -1000L))
  expect_equal(df_check$m.int32_col, c(10000L, -50000L))
  expect_equal(
    df_check$m.int128_col,
    c(1.234567890123456789e18, -9.876543210987654321e18)
  )
  expect_equal(df_check$m.uint8_col, c(0L, 255L))
  expect_equal(df_check$m.uint16_col, c(0L, 65535L))
  expect_equal(df_check$m.serial_col, c(0L, 1L))
})

test_that("kuzu_copy_from_df handles empty data frames", {
  conn <- kuzu_connection(":memory:")

  # Create a simple table
  kuzu_execute(
    conn,
    "CREATE NODE TABLE EmptyTestTable(col1 STRING, PRIMARY KEY (col1))"
  )

  # Create an empty data frame
  empty_df <- data.frame(col1 = character(0))

  # Load the empty data frame
  kuzu_copy_from_df(conn, empty_df, "EmptyTestTable")

  # Query and verify that the table is empty
  result <- kuzu_execute(conn, "MATCH (e:EmptyTestTable) RETURN count(e)")
  expect_equal(as.data.frame(result)[[1]], 0)

  # Test with a table that has multiple columns
  kuzu_execute(
    conn,
    paste("CREATE NODE TABLE AnotherEmptyTable(id INT64, name STRING, ",
          "PRIMARY KEY (id))", sep = "")
  )
  empty_df_multi <- data.frame(id = integer(0), name = character(0))
  kuzu_copy_from_df(conn, empty_df_multi, "AnotherEmptyTable")
  result_multi <- kuzu_execute(
    conn,
    "MATCH (a:AnotherEmptyTable) RETURN count(a)"
  )
  expect_equal(as.data.frame(result_multi)[[1]], 0)
})

test_that("kuzu_merge_df works for insertion and update", {
  conn <- kuzu_connection(":memory:")

  kuzu_execute(
    conn,
    paste("CREATE NODE TABLE Person(name STRING, current_city STRING, age",
          " INT64, PRIMARY KEY (name))")
  )

  # --- Test Insertion ---
  initial_data <- data.frame(
    name = c("Alice", "Bob"),
    current_city = c("New York", "London"),
    age = c(30, 25)
  )

  kuzu_copy_from_df(conn, df = initial_data, table_name = "Person")

  # Verify initial insertion
  result_initial <- kuzu_execute(
    conn,
    "MATCH (p:Person) RETURN p.name, p.current_city, p.age ORDER BY p.name"
  )
  df_initial <- as.data.frame(result_initial)
  expect_equal(nrow(df_initial), 2)
  expect_equal(df_initial$p.name, c("Alice", "Bob"))
  expect_equal(df_initial$p.current_city, c("New York", "London"))
  expect_equal(df_initial$p.age, c(30, 25))

  # --- Test Update and New Insertion ---
  update_data <- data.frame(
    name = c("Alice", "Charlie"), # Alice to be updated, Charlie to be inserted
    current_city = c("Los Angeles", "Paris"),
    age = c(31, 35)
  )

  merge_statement_update <- "MERGE (p:Person {name: name})
  ON MATCH SET p.current_city = current_city, p.age = age
  ON CREATE SET p.current_city = current_city, p.age = age"

  kuzu_merge_df(conn, df = update_data, merge_statement_update)

  # Verify update and new insertion
  result_update <- kuzu_execute(
    conn,
    "MATCH (p:Person) RETURN p.name, p.current_city, p.age ORDER BY p.name"
  )
  df_update <- as.data.frame(result_update)
  expect_equal(nrow(df_update), 3) # Alice, Bob, Charlie
  expect_equal(df_update$p.name, c("Alice", "Bob", "Charlie"))
  expect_equal(df_update$p.current_city, c("Los Angeles", "London", "Paris"))
  expect_equal(df_update$p.age, c(31, 25, 35))
})

test_that("kuzu_copy_from_csv loads data correctly", {
  conn <- kuzu_connection(":memory:")

  # Create table with corresponding Kuzu data types
  kuzu_execute(
    conn,
    "CREATE NODE TABLE CsvLoadedTypes(
    id INT64,
    name STRING,
    is_active BOOL,
    value FLOAT,
    amount DOUBLE,
    event_date DATE,
    timestamp TIMESTAMP,
    price DECIMAL(10,2),
    PRIMARY KEY (id)
  )"
  )

  temp_csv_path <- test_path("temp_mixed_types.csv")
  # Load data from CSV
  kuzu_copy_from_csv(
    conn,
    file_path = temp_csv_path,
    table_name = "CsvLoadedTypes"
  )

  # Query and verify data
  result <- kuzu_execute(
    conn,
    paste("MATCH (c:CsvLoadedTypes) RETURN c.id, c.name, c.is_active, c.value,",
          "c.amount, c.event_date, c.timestamp, c.price ORDER BY c.id")
  )
  df_check <- as.data.frame(result)

  expect_equal(nrow(df_check), 2)
  expect_equal(df_check$c.id, c(1, 2))
  expect_equal(df_check$c.name, c("Test Item", "Another Item"))
  expect_equal(df_check$c.is_active, c(TRUE, FALSE))
  expect_equal(df_check$c.value, c(1.23, 4.56))
  expect_equal(df_check$c.amount, c(10.12345, 67.89012))
  expect_equal(
    substr(as.character(df_check$c.event_date), 1, 10),
    c("2023-01-15", "2023-02-20")
  )
  # Format both actual and expected to UTC strings for a robust comparison
  expected_timestamps_csv <- as.POSIXct(c("2023-01-15 09:30:00", "2023-02-20 13:45:00"), tz = "UTC")
  expect_equal(
    format(df_check$c.timestamp, tz = "UTC", format = "%Y-%m-%d %H:%M:%S"),
    format(expected_timestamps_csv, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")
  )
})

# --- Tests for kuzu_copy_from_json ---

# Helper to create a temporary JSON file
create_temp_json <- function(file_path, content) {
  file_conn <- file(file_path, "w")
  writeLines(content, file_conn)
  close(file_conn)
}

test_that("kuzu_copy_from_json loads data correctly", {
  conn <- kuzu_connection(":memory:")

  # Create a JSON file with an array of objects
  json_content <- '[
    {"id": 101, "name": "JSON Item 1", "is_active": true, "value": 5.5},
    {"id": 102, "name": "JSON Item 2", "is_active": false, "value": 10.1}
  ]'
  temp_json_path <- "temp_json_data.json"
  create_temp_json(temp_json_path, json_content)

  # Create table with corresponding Kuzu data types
  kuzu_execute(
    conn,
    "CREATE NODE TABLE JsonLoadedTable(
    id INT64,
    name STRING,
    is_active BOOL,
    value DOUBLE,
    PRIMARY KEY (id)
  )"
  )

  # Load data from JSON
  kuzu_copy_from_json(conn, temp_json_path, "JsonLoadedTable")

  # Query and verify data
  result <- kuzu_execute(
    conn,
    paste("MATCH (j:JsonLoadedTable) RETURN j.id, j.name, j.is_active, j.value",
          " ORDER BY j.id", sep = "")
  )
  df_check <- as.data.frame(result)

  expect_equal(nrow(df_check), 2)
  expect_equal(df_check$j.id, c(101, 102))
  expect_equal(df_check$j.name, c("JSON Item 1", "JSON Item 2"))
  expect_equal(df_check$j.is_active, c(TRUE, FALSE))
  expect_equal(df_check$j.value, c(5.5, 10.1))

  # Clean up temporary file
  unlink(temp_json_path)
})

test_that("kuzu_copy_from_json handles empty JSON files", {
  conn <- kuzu_connection(":memory:")

  # Create an empty JSON file (empty array)
  json_content <- "[]"
  temp_json_path <- "temp_empty_json.json"
  create_temp_json(temp_json_path, json_content)

  # Create table
  kuzu_execute(
    conn,
    "CREATE NODE TABLE EmptyJsonTable(id INT64, name STRING, PRIMARY KEY (id))"
  )

  # Load data from empty JSON
  kuzu_copy_from_json(conn, temp_json_path, "EmptyJsonTable")

  # Query and verify that the table is empty
  result <- kuzu_execute(conn, "MATCH (e:EmptyJsonTable) RETURN count(e)")
  expect_equal(as.data.frame(result)[[1]], 0)

  unlink(temp_json_path)
})


test_that("kuzu handles data types DECIMAL and UUID", {
  conn <- kuzu_connection(":memory:")

  # Create table with various Kuzu data types
  kuzu_execute(
    conn,
    "CREATE NODE TABLE MixedTypes(
  id INT64,
  price DECIMAL,
  uuid_col UUID,
  PRIMARY KEY (id))"
  )

  # Create a data frame with corresponding R data types
  mixed_df <- data.frame(
    id = c(1L, 2L),
    price = c(99.99, 123.45),
    uuid_col = c(
      "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "09876543-21fe-dcba-0987-654321fedcba"
    ),
    stringsAsFactors = FALSE
  )

  kuzu_copy_from_df(conn, mixed_df, "MixedTypes")

  result <- kuzu_execute(
    conn,
    "MATCH (m:MixedTypes) RETURN m.id, m.price, m.uuid_col ORDER BY m.id"
  )
  all_results <- kuzu_get_all(result)

  expect_true(is.list(all_results))
  expect_true(all_results[[1]]$m.id == 1)
  expect_true(all_results[[2]]$m.id == 2)
  expect_equal(
    as.character(all_results[[1]]$m.uuid_col),
    "a1b2c3d4-e5f6-7890-1234-567890abcdef"
  )
  expect_equal(as.character(all_results[[1]]$m.price) |> as.numeric(), 99.99)
})
