test_that("Connection object is created", {
  conn <- kuzu_connection(":memory:")
  expect_s3_class(conn, "kuzu.connection.Connection")
  rm(conn)
})

test_that("Queries execute and results can be converted", {
  conn <- kuzu_connection(":memory:")
  
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
  
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
  expect_s3_class(result, "kuzu.query_result.QueryResult")
  
  df <- as.data.frame(result)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 1)
  expect_equal(df$a.name, "Alice")
  
  rm(conn, result, df)
})

test_that("Result schema functions work correctly", {
  conn <- kuzu_connection(":memory:")
  
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
  
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
  
  # Test kuzu_get_column_names
  col_names <- kuzu_get_column_names(result)
  expect_type(col_names, "character")
  expect_equal(col_names, c("a.name", "a.age"))
  
  # Test kuzu_get_column_data_types
  col_types <- kuzu_get_column_data_types(result)
  expect_type(col_types, "character")
  expect_equal(col_types, c("STRING", "INT64"))
  
  # Test kuzu_get_schema
  schema <- kuzu_get_schema(result)
  expect_type(schema, "list")
  expect_equal(schema, list("a.name" = "STRING", "a.age" = "INT64"))
  
  rm(conn, result, col_names, col_types, schema)
})

test_that("as_tibble.kuzu.query_result.QueryResult works correctly", {
  skip_if_not_installed("tibble")
  conn <- kuzu_connection(":memory:")

  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")

  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")

  tbl <- tibble::as_tibble(result)
  expect_s3_class(tbl, "tbl_df")
  expect_equal(nrow(tbl), 1)
  expect_equal(tbl$a.name, "Alice")

  rm(conn, result, tbl)
})

test_that("kuzu_get_all, kuzu_get_n, and kuzu_get_next work correctly", {
  conn <- kuzu_connection(":memory:")

  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
  kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
  kuzu_execute(conn, "CREATE (:User {name: 'Charlie', age: 35})")

  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age ORDER BY a.name")

  # Test kuzu_get_all
  all_results <- kuzu_get_all(result)
  expect_type(all_results, "list")
  expect_length(all_results, 3)
  expect_equal(all_results[[1]]$a.name, "Alice")
  expect_equal(all_results[[3]]$a.name, "Charlie")

  # Test kuzu_get_n (needs a fresh result object)
  result_n <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age ORDER BY a.name")
  first_two <- kuzu_get_n(result_n, 2)
  expect_type(first_two, "list")
  expect_length(first_two, 2)
  expect_equal(first_two[[1]]$a.name, "Alice")
  expect_equal(first_two[[2]]$a.name, "Bob")

  # Test kuzu_get_next (needs a fresh result object)
  result_next <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age ORDER BY a.name")
  expect_true(result_next$has_next())
  row1 <- kuzu_get_next(result_next)
  expect_type(row1, "list")
  expect_equal(row1$a.name, "Alice")

  expect_true(result_next$has_next())
  row2 <- kuzu_get_next(result_next)
  expect_type(row2, "list")
  expect_equal(row2$a.name, "Bob")

  expect_true(result_next$has_next())
  row3 <- kuzu_get_next(result_next)
  expect_type(row3, "list")
  expect_equal(row3$a.name, "Charlie")

  expect_false(result_next$has_next()) # No more rows
  row_null <- kuzu_get_next(result_next)
  expect_null(row_null)

  rm(conn, result, result_n, result_next, all_results, first_two, row1, row2, row3, row_null)
})
