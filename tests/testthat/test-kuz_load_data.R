
test_that("kuzu_copy_from_df works for node and rel tables", {
  db <- kuzu_database(":memory:")
  conn <- kuzu_connection(db)

  # Test Node Table
  kuzu_execute(conn, "CREATE NODE TABLE Product(id INT64, name STRING, PRIMARY KEY (id))")
  products_df <- data.frame(id = c(1, 2), name = c("Laptop", "Mouse"))
  kuzu_copy_from_df(conn, products_df, "Product")
  result <- kuzu_execute(conn, "MATCH (p:Product) RETURN p.id, p.name ORDER BY p.id")
  df_check <- as.data.frame(result)
  expect_equal(nrow(df_check), 2)
  expect_equal(df_check$p.id, c(1, 2))

  # Test Rel Table
  kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE REL TABLE Follows(FROM Person TO Person, since INT64)")
  persons_df <- data.frame(name = c("Alice", "Bob"))
  kuzu_copy_from_df(conn, persons_df, "Person")
  
  follows_df <- data.frame(from_person = "Alice", to_person = "Bob", since = 2023)
  kuzu_copy_from_df(conn, follows_df, "Follows")
  
  result_rel <- kuzu_execute(conn, "MATCH (a:Person)-[f:Follows]->(b:Person) RETURN a.name, b.name, f.since")
  df_rel_check <- as.data.frame(result_rel)
  expect_equal(nrow(df_rel_check), 1)
  expect_equal(df_rel_check$a.name, "Alice")
  expect_equal(df_rel_check$b.name, "Bob")
  expect_equal(df_rel_check$f.since, 2023)
  
  # Test error if primary key is missing
  bad_follows_df <- data.frame(start_person = "xxx", end_person = "Bob", since = 2023)
  
  expect_error(
    kuzu_copy_from_df(conn, bad_follows_df, "Follows"),
  )
})
