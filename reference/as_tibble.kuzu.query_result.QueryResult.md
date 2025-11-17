# Convert a Kuzu Query Result to a Tibble

Provides an S3 method to convert a Kuzu query result object into a
`tibble`. This requires the `tibble` package to be installed.

## Usage

``` r
# S3 method for class 'kuzu.query_result.QueryResult'
as_tibble(x, ...)
```

## Arguments

- x:

  A Kuzu query result object.

- ...:

  Additional arguments passed to `as_tibble`.

## Value

A `tibble` containing the query results.

## Examples

``` r
# \donttest{
if (requireNamespace("tibble", quietly = TRUE)) {
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
  PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")

  # Convert the result to a tibble
  tbl <- tibble::as_tibble(result)
  print(tbl)
}
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.
# }
```
