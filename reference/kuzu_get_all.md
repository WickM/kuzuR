# Retrieve All Rows from a Query Result

Fetches all rows from a Kuzu query result and returns them as a list of
lists.

## Usage

``` r
kuzu_get_all(result)
```

## Arguments

- result:

  A Kuzu query result object.

## Value

A list where each element is a list representing a row of results.

## Examples

``` r
# \donttest{
conn <- kuzu_connection(":memory:")
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
#> Error: object 'conn' not found
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#> Error: object 'conn' not found
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#> Error: object 'conn' not found
all_results <- kuzu_get_all(result)
#> Error: object 'result' not found
# }
```
