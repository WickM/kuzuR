# Load Data from a Data Frame or Tibble into a Kuzu Table

Efficiently copies data from an R `data.frame` or `tibble` into a
specified table in the Kuzu database.

## Usage

``` r
kuzu_copy_from_df(conn, df, table_name)
```

## Arguments

- conn:

  A Kuzu connection object.

- df:

  A `data.frame` or `tibble` containing the data to load. Column names
  in the data frame should match the property names in the Kuzu table.

- table_name:

  A string specifying the name of the destination table in Kuzu.

## Value

This function is called for its side effect of loading data and does not
return a value.

## Details

When loading into a relationship table, Kuzu assumes the first two
columns in the file are: FROM Node Column: The primary key of the FROM
nodes. TO Node Column: The primary key of the TO nodes.

## See also

[Kuzu Copy from
DataFrame](https://kuzudb.github.io/docs/import/copy-from-dataframe/)

## Examples

``` r
if (FALSE) { # \dontrun{
  conn <- kuzu_connection(":memory:")
  kuzu_execute(conn, "CREATE NODE TABLE User(name STRING, age INT64, 
  PRIMARY KEY (name))")
  kuzu_execute(conn, "CREATE REL TABLE Knows(FROM User TO User)")

  # Load from a data.frame
  users_df <- data.frame(name = c("Carol", "Dan"), age = c(35, 40))
  kuzu_copy_from_df(conn, users_df, "User")

  # Load from a tibble (requires pre-existing nodes)
  kuzu_execute(conn, "CREATE (u:User {name: 'Alice'}), (v:User {name: 'Bob'})")
  knows_df <- data.frame(from_person = c("Alice", "Bob"), 
  to_person = c("Bob", "Carol"))
  kuzu_copy_from_df(conn, knows_df, "Knows")

  result <- kuzu_execute(conn, "MATCH (a:User) RETURN a.name, a.age")
  print(as.data.frame(result))

  result_rel <- kuzu_execute(conn, "MATCH (a:User)-[k:Knows]->(b:User) 
  RETURN a.name, b.name")
  print(as.data.frame(result_rel))
} # }
```
