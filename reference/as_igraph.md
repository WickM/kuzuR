# Convert a Kuzu Query Result to an igraph Object

Converts a Kuzu query result into an `igraph` graph object.

## Usage

``` r
as_igraph(query_result)
```

## Arguments

- query_result:

  A `kuzu_query_result` object from
  [`kuzu_execute()`](https://wickm.github.io/kuzuR/reference/kuzu_execute.md)
  that contains a graph.

## Value

An `igraph` object.

## Details

This function takes a `kuzu_query_result` object, converts it to a
`networkx` graph in Python, extracts the nodes and edges into R data
frames, and then constructs an `igraph` object. It is the final step in
the `kuzu_execute -> as_igraph` workflow.

## Examples

``` r
# \donttest{
if (requireNamespace("igraph", quietly = TRUE)) {
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, 
  PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE REL TABLE Knows(FROM Person TO Person)")
  kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'}), 
  (q:Person {name: 'Bob'})")
  kuzu_execute(conn, "MATCH (a:Person), (b:Person) WHERE
                                                    a.name='Alice' AND 
                                                    b.name='Bob'
                                                    CREATE (a)-[:Knows]->(b)"
)

  res <- kuzu_execute(conn, "MATCH (p:Person)-[k:Knows]->(q:Person) 
  RETURN p, k, q")
  g <- as_igraph(res)
  print(g)
  rm(conn, res, g)
}
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.
# }
```
