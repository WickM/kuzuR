# Convert a Kuzu Query Result to a tidygraph Object

Converts a Kuzu query result into a `tidygraph` `tbl_graph` object.

## Usage

``` r
as_tidygraph(query_result)
```

## Arguments

- query_result:

  A `kuzu_query_result` object from
  [`kuzu_execute()`](https://wickm.github.io/kuzuR/reference/kuzu_execute.md)
  that contains a graph.

## Value

A `tbl_graph` object.

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("tidygraph", quietly = TRUE)) {
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, 
  PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'})")
  res <- kuzu_execute(conn, "MATCH (p:Person) RETURN p")
  g_tidy <- as_tidygraph(res)
  print(g_tidy)
  rm(conn, res, g_tidy)
}
} # }
```
