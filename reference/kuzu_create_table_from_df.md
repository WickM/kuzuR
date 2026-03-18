# Create a Kuzu Table from a Data Frame

Infers a schema from an R `data.frame` or `tibble` and creates a
corresponding NODE table in the Kuzu database.

## Usage

``` r
kuzu_create_table_from_df(conn, df, table_name, primary_key)
```

## Arguments

- conn:

  A Kuzu connection object.

- df:

  A `data.frame` or `tibble` from which to infer the schema.

- table_name:

  A string specifying the name of the new table in Kuzu.

- primary_key:

  An optional string specifying the column to be used as the primary
  key. If not provided, no primary key will be set.

## Value

This function is called for its side effect of creating a table and does
not return a value.

## Examples

``` r
# \donttest{
  conn <- kuzu_connection(":memory:")
#> Error in py_run_string_impl(code, local, convert): ModuleNotFoundError: No module named 'kuzu'
#> Run `reticulate::py_last_error()` for details.

  my_df <- data.frame(
    name = c("Alice", "Bob"),
    age = c(25L, 30L),
    height = c(1.75, 1.80),
    is_student = c(TRUE, FALSE),
    birth_date = as.Date(c("1999-01-01", "1994-05-15"))
  )

  kuzu_create_table_from_df(conn, my_df, "Person", primary_key = "name")
#> Error: object 'conn' not found

  # Now you can load data into the created table
  kuzu_copy_from_df(conn, my_df, "Person")
#> Error: object 'conn' not found

  result <- kuzu_execute(conn, "MATCH (p:Person) RETURN *")
#> Error: object 'conn' not found
  print(as.data.frame(result))
#> Error: object 'result' not found
# }
```
