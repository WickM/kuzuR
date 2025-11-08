# Load Data from a JSON File into a Kuzu Table

Loads data from a JSON file into a specified table in the Kuzu database.
This function also ensures the JSON extension is loaded and available.

## Usage

``` r
kuzu_copy_from_json(conn, file_path, table_name)
```

## Arguments

- conn:

  A Kuzu connection object.

- file_path:

  A string specifying the path to the JSON file.

- table_name:

  A string specifying the name of the destination table in Kuzu.

## Value

This function is called for its side effect of loading data and does not
return a value.

## See also

[Kuzu JSON
Import](https://kuzudb.github.io/docs/import/copy-from-json/), [Kuzu
JSON Extension](https://kuzudb.github.io/docs/extensions/json/)

## Examples

``` r
if (FALSE) { # \dontrun{
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE Product(id INT64, name STRING, 
  PRIMARY KEY (id))")

  # Create a temporary JSON file
  json_file <- tempfile(fileext = ".json")
  json_data <- '[{"id": 1, "name": "Laptop"}, {"id": 2, "name": "Mouse"}]'
  writeLines(json_data, json_file)

  # Load data from JSON
  kuzu_copy_from_json(conn, json_file, "Product")

  # Verify the data
  result <- kuzu_execute(conn, "MATCH (p:Product) RETURN p.id, p.name")
  print(as.data.frame(result))

  # Clean up the temporary file
  unlink(json_file)
} # }
```
