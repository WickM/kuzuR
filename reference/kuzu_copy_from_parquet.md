# Load Data from a Parquet File into a Kuzu Table

Loads data from a Parquet file into a specified table in the Kuzu
database.

## Usage

``` r
kuzu_copy_from_parquet(conn, file_path, table_name)
```

## Arguments

- conn:

  A Kuzu connection object.

- file_path:

  A string specifying the path to the Parquet file.

- table_name:

  A string specifying the name of the destination table in Kuzu.

## Value

This function is called for its side effect of loading data and does not
return a value.

## See also

[Kuzu Parquet Import](https://kuzudb.github.io/docs/import/parquet/)

## Examples

``` r
if (FALSE) { # \dontrun{
  if (requireNamespace("arrow", quietly = TRUE)) {
    conn <- kuzu_connection(":memory:")
    kuzu_execute(conn, "CREATE NODE TABLE Country(name STRING, code STRING, 
    PRIMARY KEY (name))")

    # Create a temporary Parquet file
    parquet_file <- tempfile(fileext = ".parquet")
    country_df <- data.frame(name = c("USA", "Canada"), code = c("US", "CA"))
    arrow::write_parquet(country_df, parquet_file)

    # Load data from Parquet
    kuzu_copy_from_parquet(conn, parquet_file, "Country")

    # Verify the data
    result <- kuzu_execute(conn, "MATCH (c:Country) RETURN c.name, c.code")
    print(as.data.frame(result))

    # Clean up the temporary file
    unlink(parquet_file)
  }
} # }
```
