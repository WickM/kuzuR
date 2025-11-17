# Get Column Names from a Query Result

Retrieves the names of the columns in a Kuzu query result.

## Usage

``` r
kuzu_get_column_names(result)
```

## Arguments

- result:

  A Kuzu query result object.

## Value

A character vector of column names.

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
kuzu_get_column_names(result)
#> Error: object 'result' not found
# }
```
