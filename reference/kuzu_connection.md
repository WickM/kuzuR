# Create a Connection to a Kuzu Database

Establishes a connection to a Kuzu database. If the database does not
exist at the specified path, it will be created. This function combines
the database initialization and connection steps into a single call.

## Usage

``` r
kuzu_connection(path)
```

## Arguments

- path:

  A string specifying the file path for the database. For an in-memory
  database, use `":memory:"`.

## Value

A Python object representing the connection to the Kuzu database.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create an in-memory database and connection
conn <- kuzu_connection(":memory:")

# Create or connect to an on-disk database
conn_disk <- kuzu_connection("my_kuzu_db")
} # }
```
