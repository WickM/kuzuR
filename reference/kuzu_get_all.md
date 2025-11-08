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
if (FALSE) { # \dontrun{
conn <- kuzu_connection(":memory:")
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
all_results <- kuzu_get_all(result)
} # }
```
