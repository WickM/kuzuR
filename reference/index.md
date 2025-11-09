# Package index

## Core Kuzu Connection and Querying

- [`kuzu_connection()`](https://wickm.github.io/kuzuR/reference/kuzu_connection.md)
  : Create a Connection to a Kuzu Database
- [`kuzu_execute()`](https://wickm.github.io/kuzuR/reference/kuzu_execute.md)
  : Execute a Cypher Query
- [`kuzu_get_all()`](https://wickm.github.io/kuzuR/reference/kuzu_get_all.md)
  : Retrieve All Rows from a Query Result
- [`kuzu_get_n()`](https://wickm.github.io/kuzuR/reference/kuzu_get_n.md)
  : Retrieve the First N Rows from a Query Result
- [`kuzu_get_next()`](https://wickm.github.io/kuzuR/reference/kuzu_get_next.md)
  : Retrieve the Next Row from a Query Result
- [`kuzu_get_column_names()`](https://wickm.github.io/kuzuR/reference/kuzu_get_column_names.md)
  : Get Column Names from a Query Result
- [`kuzu_get_column_data_types()`](https://wickm.github.io/kuzuR/reference/kuzu_get_column_data_types.md)
  : Get Column Data Types from a Query Result
- [`kuzu_get_schema()`](https://wickm.github.io/kuzuR/reference/kuzu_get_schema.md)
  : Get Schema from a Query Result

## Data Loading

- [`kuzu_copy_from_csv()`](https://wickm.github.io/kuzuR/reference/kuzu_copy_from_csv.md)
  : Load Data from a CSV File into a Kuzu Table
- [`as.data.frame(`*`<kuzu.query_result.QueryResult>`*`)`](https://wickm.github.io/kuzuR/reference/as.data.frame.kuzu.query_result.QueryResult.md)
  : Convert a Kuzu Query Result to a Data Frame
- [`as_tibble(`*`<kuzu.query_result.QueryResult>`*`)`](https://wickm.github.io/kuzuR/reference/as_tibble.kuzu.query_result.QueryResult.md)
  : Convert a Kuzu Query Result to a Tibble
- [`kuzu_copy_from_df()`](https://wickm.github.io/kuzuR/reference/kuzu_copy_from_df.md)
  : Load Data from a Data Frame or Tibble into a Kuzu Table
- [`kuzu_copy_from_json()`](https://wickm.github.io/kuzuR/reference/kuzu_copy_from_json.md)
  : Load Data from a JSON File into a Kuzu Table
- [`kuzu_copy_from_parquet()`](https://wickm.github.io/kuzuR/reference/kuzu_copy_from_parquet.md)
  : Load Data from a Parquet File into a Kuzu Table
- [`kuzu_merge_df()`](https://wickm.github.io/kuzuR/reference/kuzu_merge_df.md)
  : Merge Data from a Data Frame into Kuzu using a Merge Query

## Graph Integrations

- [`as_igraph()`](https://wickm.github.io/kuzuR/reference/as_igraph.md)
  : Convert a Kuzu Query Result to an igraph Object
- [`as_tidygraph()`](https://wickm.github.io/kuzuR/reference/as_tidygraph.md)
  : Convert a Kuzu Query Result to a tidygraph Object

## Installation

- [`install_kuzu()`](https://wickm.github.io/kuzuR/reference/install_kuzu.md)
  : Install the Kuzu Python package
