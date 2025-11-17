# Convert a Kuzu Query Result to a Data Frame

Provides an S3 method to seamlessly convert a Kuzu query result object
into a standard R `data.frame`.

## Usage

``` r
# S3 method for class 'kuzu.query_result.QueryResult'
as.data.frame(x, ...)
```

## Arguments

- x:

  A Kuzu query result object.

- ...:

  Additional arguments passed to `as.data.frame`.

## Value

An R `data.frame` containing the query results.

## Examples

``` r
# \donttest{
conn <- kuzu_connection(":memory:")
#> Downloading uv...
#> Done!
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
#> Error: object 'conn' not found
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
#> Error: object 'conn' not found
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
#> Error: object 'conn' not found

# Convert the result to a data.frame
df <- as.data.frame(result)
#> Error: object 'result' not found
print(df)
#> function (x, df1, df2, ncp, log = FALSE) 
#> {
#>     if (missing(ncp)) 
#>         .Call(C_df, x, df1, df2, log)
#>     else .Call(C_dnf, x, df1, df2, ncp, log)
#> }
#> <bytecode: 0x563817034210>
#> <environment: namespace:stats>
# }
```
