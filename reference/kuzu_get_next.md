# Retrieve the Next Row from a Query Result

Fetches the next available row from a Kuzu query result. This function
can be called repeatedly to iterate through results one by one.

## Usage

``` r
kuzu_get_next(result)
```

## Arguments

- result:

  A Kuzu query result object.

## Value

A list representing the next row, or `NULL` if no more rows are
available.

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
row1 <- kuzu_get_next(result)
#> Error: object 'result' not found
row2 <- kuzu_get_next(result)
#> Error: object 'result' not found
# }
```
