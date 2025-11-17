# Retrieve the First N Rows from a Query Result

Fetches the first `n` rows from a Kuzu query result.

## Usage

``` r
kuzu_get_n(result, n)
```

## Arguments

- result:

  A Kuzu query result object.

- n:

  The number of rows to retrieve.

## Value

A list of the first `n` rows.

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
kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
#> Error: object 'conn' not found
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#> Error: object 'conn' not found
first_row <- kuzu_get_n(result, 1)
#> Error: object 'result' not found
# }
```
