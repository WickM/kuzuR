# Load Data from a CSV File into a Kuzu Table

Loads data from a CSV file into a specified table in the Kuzu database.

## Usage

``` r
kuzu_copy_from_csv(conn, file_path, table_name, optional_csv_parameter = NULL)
```

## Arguments

- conn:

  A Kuzu connection object.

- file_path:

  A string specifying the path to the CSV file.

- table_name:

  A string specifying the name of the destination table in Kuzu.

- optional_csv_parameter:

  An optional parameter for CSV-specific configurations (e.g.,
  delimiter, header). Refer to Kuzu documentation for available options.

## Value

This function is called for its side effect of loading data and does not
return a value.

## See also

[Kuzu CSV Import](https://kuzudb.github.io/docs/import/csv/)

## Examples

``` r
if (FALSE) { # \dontrun{
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE City(name STRING, population INT64, 
  PRIMARY KEY (name))")

  # Create a temporary CSV file
  csv_file <- tempfile(fileext = ".csv")
  write.csv(data.frame(name = c("Berlin", "London"), 
  population = c(3645000, 8982000)),
            csv_file, row.names = FALSE)

  # Load data from CSV
  kuzu_copy_from_csv(conn, csv_file, "City")

  # Verify the data
  result <- kuzu_execute(conn, "MATCH (c:City) RETURN c.name, c.population")
  print(as.data.frame(result))

  # Clean up the temporary file
  unlink(csv_file)
} # }
```
