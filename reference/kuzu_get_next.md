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
if (FALSE) { # \dontrun{
conn <- kuzu_connection(":memory:")
kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64,
PRIMARY KEY (name))")
kuzu_execute(conn, "CREATE (:User {name: 'Alice', age: 25})")
kuzu_execute(conn, "CREATE (:User {name: 'Bob', age: 30})")
result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
row1 <- kuzu_get_next(result)
row2 <- kuzu_get_next(result)
} # }
```
