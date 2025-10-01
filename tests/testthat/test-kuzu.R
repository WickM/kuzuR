library(testthat)
library(kuzuR)

# Helper function to skip tests if kuzu is not available
skip_if_no_kuzu <- function() {
  if (!reticulate::py_module_available("kuzu")) {
    skip("kuzu Python package not available for testing")
  }
}

test_that("Database and connection objects can be created", {
  skip_if_no_kuzu()
  
  # Test in-memory database
  db_mem <- kuzu_database(":memory:")
  expect_s3_class(db_mem, "kuzu.database.Database")
  conn_mem <- kuzu_connection(db_mem)
  expect_s3_class(conn_mem, "kuzu.connection.Connection")
  
  # Test on-disk database
  db_disk_path <- tempfile()
  db_disk <- kuzu_database(db_disk_path)
  expect_s3_class(db_disk, "kuzu.database.Database")
  conn_disk <- kuzu_connection(db_disk)
  expect_s3_class(conn_disk, "kuzu.connection.Connection")
  
  # Clean up the on-disk database
  rm(db_disk, conn_disk)
  gc() # Garbage collect to release file handles
  unlink(db_disk_path, recursive = TRUE)
})

test_that("Schema and data manipulation queries execute correctly", {
  skip_if_no_kuzu()
  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  
  # Create schema
  expect_no_error(kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))"))
  expect_no_error(kuzu_execute(conn, "CREATE REL TABLE Follows(FROM User TO User, since INT64)"))
  
  # Insert data
  expect_no_error(kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})"))
  expect_no_error(kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})"))
  expect_no_error(kuzu_execute(conn, "MATCH (a:User), (b:User) WHERE a.name = 'Alice' AND b.name = 'Bob' CREATE (a)-[:Follows {since: 2023}]->(b)"))
})

test_that("Query results are handled and converted correctly", {
  skip_if_no_kuzu()
  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
  kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
  
  result <- kuzu_execute(conn, "MATCH (u:User) RETURN u.name, u.age ORDER BY u.name")
  
  # Test as.data.frame conversion
  df <- as.data.frame(result)
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 2)
  expect_equal(names(df), c("u.name", "u.age"))
  expect_equal(df$u.name, c("Alice", "Bob"))
  
  # Test as_tibble conversion
  if (requireNamespace("tibble", quietly = TRUE)) {
    tbl <- tibble::as_tibble(result)
    expect_s3_class(tbl, "tbl_df")
    expect_equal(nrow(tbl), 2)
    expect_equal(names(tbl), c("u.name", "u.age"))
    expect_equal(tbl$u.name, c("Alice", "Bob"))
  }
  
  # Test as_tibble conversion
  if (requireNamespace("tibble", quietly = TRUE)) {
    tbl <- tibble::as_tibble(result)
    expect_s3_class(tbl, "tbl_df")
    expect_equal(nrow(tbl), 2)
    expect_equal(names(tbl), c("u.name", "u.age"))
    expect_equal(tbl$u.name, c("Alice", "Bob"))
  }
  
  # Test kuzu_get_all
  result <- kuzu_execute(conn, "MATCH (u:User) RETURN u.name, u.age ORDER BY u.name")
  all_res <- kuzu_get_all(result)
  expect_type(all_res, "list")
  expect_length(all_res, 2)
  expect_equal(all_res[[1]], list("Alice", 25L))
  
  # Test kuzu_get_n and kuzu_get_next
  result <- kuzu_execute(conn, "MATCH (u:User) RETURN u.name, u.age ORDER BY u.name")
  n_res <- kuzu_get_n(result, 1)
  expect_length(n_res, 1)
  expect_equal(n_res[[1]], list("Alice", 25L))
  
  next_res <- kuzu_get_next(result)
  expect_equal(next_res, list("Bob", 30L))
})

test_that("Data can be copied from a data.frame and a tibble", {
  skip_if_no_kuzu()
  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))")
  
  # Test with data.frame
  users_df <- data.frame(name = c("Carol", "Dan"), age = c(35, 40))
  expect_no_error(kuzu_copy_from_df(conn, "User", users_df))
  
  result_df <- kuzu_execute(conn, "MATCH (u:User) WHERE u.name IN ['Carol', 'Dan'] RETURN count(u)")
  count_df <- as.data.frame(result_df)
  expect_equal(count_df[[1]], 2L)
  
  # Test with tibble, if tibble is installed
  if (requireNamespace("tibble", quietly = TRUE)) {
    users_tbl <- tibble::tibble(name = c("Eve", "Frank"), age = c(45, 50))
    expect_no_error(kuzu_copy_from_df(conn, "User", users_tbl))
    
    result_tbl <- kuzu_execute(conn, "MATCH (u:User) WHERE u.name IN ['Eve', 'Frank'] RETURN count(u)")
    count_tbl <- as.data.frame(result_tbl)
    expect_equal(count_tbl[[1]], 2L)
  } else {
    skip("tibble package not installed, skipping tibble test")
  }
})
