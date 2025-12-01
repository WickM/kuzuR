# Graph Conversion Functions for kuzuR

#helper
as_networkx <- function(query_result) {
  if (!inherits(query_result, "kuzu.query_result.QueryResult")) {
    stop("Input must be a kuzu_query_result object.", call. = FALSE)
  }
  nx_graph <- query_result$get_as_networkx()
  # Assign a specific class for S3 dispatch
  class(nx_graph) <- c("kuzu_networkx", class(nx_graph))
  nx_graph
}

as_data_frame_kuzu_networkx <- function(x, ...) {
  main <- reticulate::import_main()
  main$nx_graph <- x

  # Python script to extract nodes and edges into pandas data frames
  reticulate::py_run_string(
    "
import networkx as nx
import pandas as pd

def flatten_attributes(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_attributes(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

nodes_list = []
for node_id, attributes in nx_graph.nodes(data=True):
    flat_attrs = flatten_attributes(attributes)
    if '_label' in flat_attrs:
        flat_attrs['label'] = flat_attrs.pop('_label')
    
    # Remove internal properties
    keys_to_remove = [k for k in flat_attrs.keys() if k.startswith('_')]
    for k in keys_to_remove:
        del flat_attrs[k]
        
    flat_attrs['name'] = node_id
    nodes_list.append(flat_attrs)

nodes_df = pd.DataFrame(nodes_list)

if 'name' in nodes_df.columns:
    cols = ['name'] + [col for col in nodes_df.columns if col != 'name']
    nodes_df = nodes_df[cols]

edges_df = nx.to_pandas_edgelist(nx_graph)
  "
  )

  # Retrieve the data frames into R
  list(
    nodes = reticulate::py$nodes_df,
    edges = reticulate::py$edges_df
  )
}

#' Convert a Kuzu Query Result to an igraph Object
#'
#' @description
#' Converts a Kuzu query result into an `igraph` graph object.
#'
#' @details
#' This function takes a `kuzu_query_result` object, converts it to a
#' `networkx` graph in Python, extracts the nodes and edges into R data frames,
#' and then constructs an `igraph` object. It is the final step in the
#' `kuzu_execute -> as_igraph` workflow.
#'
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()` that 
#' contains a graph.
#' @return An `igraph` object.
#' @importFrom igraph graph_from_data_frame
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, 
#'   PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE REL TABLE Knows(FROM Person TO Person)")
#'   kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'}), 
#'   (q:Person {name: 'Bob'})")
#'   kuzu_execute(conn, "MATCH (a:Person), (b:Person) WHERE
#'                                                     a.name='Alice' AND 
#'                                                     b.name='Bob'
#'                                                     CREATE (a)-[:Knows]->(b)"
#' )
#'
#'   res <- kuzu_execute(conn, "MATCH (p:Person)-[k:Knows]->(q:Person) 
#'   RETURN p, k, q")
#'   g <- as_igraph(res)
#'   print(g)
#'   rm(conn, res, g)
#' }
#' }
as_igraph <- function(query_result) {
  graph_dfs <- as_data_frame_kuzu_networkx(as_networkx(query_result))
  igraph::graph_from_data_frame(d = graph_dfs$edges, vertices = graph_dfs$nodes)
}

#' Convert a Kuzu Query Result to a tidygraph Object
#'
#' @description
#' Converts a Kuzu query result into a `tidygraph` `tbl_graph` object.
#'
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()` that 
#' contains a graph.
#' @return A `tbl_graph` object.
#' @importFrom tidygraph tbl_graph
#' @export
#' @examples
#' \donttest{
#' if (requireNamespace("tidygraph", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, 
#'   PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'})")
#'   res <- kuzu_execute(conn, "MATCH (p:Person) RETURN p")
#'   g_tidy <- as_tidygraph(res)
#'   print(g_tidy)
#'   rm(conn, res, g_tidy)
#' }
#' }
as_tidygraph <- function(query_result) {
  graph_dfs <- as_data_frame_kuzu_networkx(as_networkx(query_result))
  tidygraph::tbl_graph(nodes = graph_dfs$nodes, edges = graph_dfs$edges)
}
