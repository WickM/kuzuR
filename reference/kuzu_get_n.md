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
if (FALSE) { # \dontrun{
conn <- kuzu_connection(":memory:")
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, 
PRIMARY KEY (name))")
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
first_row <- kuzu_get_n(result, 1)
} # }
```
