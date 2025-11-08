# Merge Data from a Data Frame into Kuzu using a Merge Query

This function is intended for merging data from an R `data.frame` into
Kuzu using a specified merge query. It leverages Python's reticulate to
interact with Kuzu's Python API.

## Usage

``` r
kuzu_merge_df(conn, df, merge_query)
```

## Arguments

- conn:

  A Kuzu connection object.

- df:

  A `data.frame` or `tibble` containing the data to merge.

- merge_query:

  A string representing the Kuzu query for merging data.

## Value

This function is called for its side effect of merging data and does not
return a value.

## See also

[Kuzu Copy from
DataFrame](https://kuzudb.github.io/docs/import/copy-from-dataframe/)

## Examples

``` r
if (FALSE) { # \dontrun{
my_data <- data.frame(
   name = c("Alice", "Bob"),
   item = c("Book", "Pen"),
   current_city = c("New York", "London")
 )

 merge_statement <- "MERGE (p:Person {name: df.name})
 MERGE (i:Item {name: df.item})
 MERGE (p)-[:PURCHASED]->(i)
 ON MATCH SET p.current_city = df.current_city
 ON CREATE SET p.current_city = df.current_city"

 kuzu_merge_df(conn, my_data, merge_statement)

 # Example with a different merge query structure:
 my_data_2 <- data.frame(
   person_name = c("Charlie"),
   purchased_item = c("Laptop"),
   city = c("Paris")
 )
#
 merge_statement_2 <- "MERGE (p:Person {name: person_name})
 MERGE (i:Item {name: purchased_item})
 MERGE (p)-[:PURCHASED]->(i)
 ON MATCH SET p.current_city = city
 ON CREATE SET p.current_city = city"

 kuzu_merge_df(conn, my_data_2, merge_statement_2)
 } # }
```
