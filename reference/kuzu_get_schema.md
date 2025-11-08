# Get Schema from a Query Result

Retrieves the schema (column names and data types) of a Kuzu query
result.

## Usage

``` r
kuzu_get_schema(result)
```

## Arguments

- result:

  A Kuzu query result object.

## Value

A named list where names are column names and values are data types.

## Examples

``` r
if (FALSE) { # \dontrun{
conn <- kuzu_connection(":memory:")
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
kuzu_get_schema(result)
} # }
```
