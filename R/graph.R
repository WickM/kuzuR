# Graph Conversion Functions for kuzuR

#' Convert a Kuzu Query Result to a NetworkX Object
#'
#' @description
#' This is a helper function that takes the result of `kuzu_execute()` and
#' calls the `.get_as_networkx()` method on the underlying Python object.
#'
#' @details
#' This function serves as the first step in a two-step process to convert
#' Kuzu graph data into R-native graph objects. It returns a `reticulate`
#' proxy object for a Python `networkx` graph. The class of this object is
#' set to allow dispatch to a corresponding `as.data.frame` method.
#'
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()`.
#' @return A `networkx.classes.graph.Graph` object (via `reticulate`).
#' @export
as_networkx <- function(query_result) {
  if (!inherits(query_result, "kuzu.query_result.QueryResult")) {
    stop("Input must be a kuzu_query_result object.", call. = FALSE)
  }
  nx_graph <- query_result$get_as_networkx()
  # Assign a specific class for S3 dispatch
  class(nx_graph) <- c("kuzu_networkx", class(nx_graph))
  nx_graph
}

#' Convert a kuzu_networkx Object to a List of Data Frames
#'
#' @description
#' This S3 method converts the `reticulate`-wrapped `networkx` graph object
#' into a standard R list containing a `nodes` data frame and an `edges`
#' data frame.
#'
#' @details
#' This function shells out to Python via `reticulate` to perform the
#' conversion. It uses `pandas` and `networkx` to extract the node and edge
#' attributes into data frames that can be easily used in R. This is the
#' core of the conversion process.
#'
#' @param x A `kuzu_networkx` object from `as_networkx()`.
#' @param ... Additional arguments (not used).
#' @return A list containing two data frames: `nodes` and `edges`.
#' @export
#' @method as.data.frame kuzu_networkx
as.data.frame.kuzu_networkx <- function(x, ...) {
  main <- reticulate::import_main()
  main$nx_graph <- x

  # Python script to extract nodes and edges into pandas data frames
  reticulate::py_run_string("
import networkx as nx
import pandas as pd

# nx.to_pandas_edgelist() uses the networkx node ID for source/target.
# We must extract that same ID to create a valid vertices data frame for igraph.
nodes_list = []
for node_id, attributes in nx_graph.nodes(data=True):
    # The attributes dictionary contains the properties from Kuzu.
    # We add the networkx ID to it.
    attributes['name'] = node_id
    nodes_list.append(attributes)

nodes_df = pd.DataFrame(nodes_list)

# Reorder columns to ensure the 'name' column (the ID) is first,
# as this is what igraph::graph_from_data_frame uses by default to match vertices.
if 'name' in nodes_df.columns:
    cols = ['name'] + [col for col in nodes_df.columns if col != 'name']
    nodes_df = nodes_df[cols]

# Extract edges, which will correctly use the node_id for source/target
edges_df = nx.to_pandas_edgelist(nx_graph)
  ")

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
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()` that contains a graph.
#' @return An `igraph` object.
#' @importFrom igraph graph_from_data_frame
#' @export
#' @examples
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE REL TABLE Knows(FROM Person TO Person)")
#'   kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'}), (q:Person {name: 'Bob'})")
#'   kuzu_execute(conn, "MATCH (a:Person), (b:Person) WHERE a.name='Alice' AND b.name='Bob' CREATE (a)-[:Knows]->(b)")
#'   
#'   res <- kuzu_execute(conn, "MATCH (p:Person)-[k:Knows]->(q:Person) RETURN p, k, q")
#'   g <- as_igraph(res)
#'   print(g)
#'   rm(conn, res, g)
#' }
as_igraph <- function(query_result) {
  graph_dfs <- as.data.frame(as_networkx(query_result))
  igraph::graph_from_data_frame(d = graph_dfs$edges, vertices = graph_dfs$nodes)
}

#' Convert a Kuzu Query Result to a tidygraph Object
#'
#' @description
#' Converts a Kuzu query result into a `tidygraph` `tbl_graph` object.
#'
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()` that contains a graph.
#' @return A `tbl_graph` object.
#' @importFrom tidygraph tbl_graph
#' @export
#' @examples
#' if (requireNamespace("tidygraph", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'})")
#'   res <- kuzu_execute(conn, "MATCH (p:Person) RETURN p")
#'   g_tidy <- as_tidygraph(res)
#'   print(g_tidy)
#'   rm(conn, res, g_tidy)
#' }
as_tidygraph <- function(query_result) {
  graph_dfs <- as.data.frame(as_networkx(query_result))
  tidygraph::tbl_graph(nodes = graph_dfs$nodes, edges = graph_dfs$edges)
}

#' Convert a Kuzu Query Result to a g6R Object
#'
#' @description
#' Converts a Kuzu query result into a `g6R` object for interactive visualization.
#'
#' @param query_result A `kuzu_query_result` object from `kuzu_execute()` that contains a graph.
#' @return A `g6R` HTML widget object.
#' @importFrom g6R g6
#' @export
#' @examples
#' if (requireNamespace("g6R", quietly = TRUE)) {
#'   conn <- kuzu_connection(":memory:")
#'   kuzu_execute(conn, "CREATE NODE TABLE Person(name STRING, PRIMARY KEY (name))")
#'   kuzu_execute(conn, "CREATE (p:Person {name: 'Alice'})")
#'   res <- kuzu_execute(conn, "MATCH (p:Person) RETURN p")
#'   g_g6R <- as_g6R(res)
#'   # print(g_g6R) # Prints the interactive widget
#'   rm(conn, res, g_g6R)
#' }
as_g6R <- function(query_result) {
  graph_dfs <- as.data.frame(as_networkx(query_result))
  
  # g6R requires specific column names: 'id' for nodes, and 'source'/'target' for edges.
  nodes_df <- graph_dfs$nodes
  edges_df <- graph_dfs$edges
  
  # The 'name' column from our conversion holds the unique ID. Rename it for g6R.
  names(nodes_df)[names(nodes_df) == "name"] <- "id"
  
  g6R::g6(nodes = nodes_df, edges = edges_df)
}
as_g6r <- as_g6R
