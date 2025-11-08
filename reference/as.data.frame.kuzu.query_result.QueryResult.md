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
if (FALSE) { # \dontrun{
conn <- kuzu_connection(":memory:")
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")

# Convert the result to a data.frame
df <- as.data.frame(result)
print(df)
} # }
```
