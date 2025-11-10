# Tests for graph conversion functions

test_that("Graph conversion functions work correctly with the new S3 method design", {
  testthat::skip_on_cran()
  testthat::skip_if_not(reticulate::py_module_available("kuzu"), "kuzu python module not available for testing")
  # Skip if packages are not installed
  skip_if_not_installed("igraph")
  skip_if_not_installed("tidygraph")
  skip_if_not(
    reticulate::py_module_available("networkx"),
    "networkx Python package not available"
  )

  # 1. Set up an in-memory database and connection
  conn <- kuzu_connection(":memory:")

  # 2. Create schema and data
  kuzu_execute(
    conn,
    "CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name))"
  )
  kuzu_execute(
    conn,
    "CREATE REL TABLE Knows(FROM Person TO Person, since INT64)"
  )
  kuzu_execute(conn, "CREATE (p:Person {name: 'Alice', age: 30})")
  kuzu_execute(conn, "CREATE (p:Person {name: 'Bob', age: 40})")
  kuzu_execute(
    conn,
    paste("MATCH (a:Person), (b:Person) WHERE a.name = 'Alice' AND b.name =",
          "'Bob' CREATE (a)-[:Knows {since: 2021}]->(b)")
  )

  # 3. Execute a query that returns a graph
  query_res <- kuzu_execute(
    conn,
    "MATCH (p:Person)-[k:Knows]->(q:Person) RETURN p, k, q"
  )

  # 4. Test as_igraph()
  g_igraph <- as_igraph(query_res)
  expect_s3_class(g_igraph, "igraph")
  expect_equal(igraph::vcount(g_igraph), 2)
  expect_equal(igraph::ecount(g_igraph), 1)
  node_df_igraph <- igraph::as_data_frame(g_igraph, "vertices")
  # networkx combines table name and primary key for the node ID
  expect_equal(sort(node_df_igraph$name), c("Person_Alice", "Person_Bob"))

  # 5. Test as_tidygraph()
  g_tidy <- as_tidygraph(query_res)
  expect_s3_class(g_tidy, "tbl_graph")
  expect_equal(
    g_tidy %>% tidygraph::activate(nodes) %>% as.data.frame() %>% nrow(),
    2
  )
  expect_equal(
    g_tidy %>% tidygraph::activate(edges) %>% as.data.frame() %>% nrow(),
    1
  )

  # 7. Clean up
  rm(conn, query_res, g_igraph, g_tidy)
})

test_that("as_networkx throws error for invalid input", {
  expect_error(
    as_networkx("not a query result"),
    "Input must be a kuzu_query_result object."
  )
})
