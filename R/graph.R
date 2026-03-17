# Graph Conversion Functions for kuzuR

# Cache environment for graph data extraction
.kuzu_graph_cache_env <- new.env(parent = emptyenv())

# Helper function to convert internal ID (list with offset and table) to unique string
internal_id_to_string <- function(internal_id) {
  if (
    is.list(internal_id) &&
      !is.null(internal_id$offset) &&
      !is.null(internal_id$table)
  ) {
    paste0(internal_id$table, ":", internal_id$offset)
  } else {
    as.character(internal_id)
  }
}

# Helper function to extract node and edge data from query result
# Uses internal caching to avoid calling get_all() multiple times on the same query result
extract_graph_data <- function(query_result) {
  # Use a simple approach: cache the result in the query result object itself
  # Since we can't add R attributes to Python objects, we use a hash of the object
  # as the key in a global cache

  # Get a unique identifier for this query result
  qr_hash <- digest::sha1(as.character(query_result))

  # Check cache
  if (exists(qr_hash, envir = .kuzu_graph_cache_env)) {
    return(get(qr_hash, envir = .kuzu_graph_cache_env))
  }

  all_rows_values <- query_result$get_all()

  # Named list keyed by composite "label:name" — O(1) deduplication
  nodes_map <- list()
  edges <- list()
  # Mapping from internal node ID (table:offset) to node name (for edges)
  node_id_to_name <- character(0)

  if (length(all_rows_values) == 0) {
    return(list(nodes = list(), edges = list()))
  }

  # First pass: collect all nodes
  for (row in all_rows_values) {
    for (i in seq_along(row)) {
      value <- row[[i]]

      # Check if this is a node (has _label and _id but NOT _src/_dst - those are edge properties)
      if (
        is.list(value) &&
          !is.null(value[["_label"]]) &&
          !is.null(value[["_id"]]) &&
          is.null(value[["_src"]]) &&
          is.null(value[["_dst"]])
      ) {
        node_internal_id <- internal_id_to_string(value[["_id"]])
        node_label <- value[["_label"]]
        node_name <- node_internal_id # Default to internal ID

        # If the node has a 'name' attribute, use that as the identifier
        if (!is.null(value[["name"]])) {
          node_name <- as.character(value[["name"]])
        }

        # Composite key prevents collisions between nodes from different tables
        # that happen to share the same 'name' attribute value.
        # This qualified key is used as the canonical node identifier everywhere
        # (node data frame 'name' column AND edge from/to) so that nodes from
        # different labels with the same raw name are never silently merged.
        node_key <- paste0(node_label, ":", node_name)

        if (is.null(nodes_map[[node_key]])) {
          node_data <- list(
            name = node_key, # qualified name as canonical identifier
            label = node_label
          )

          # Add other attributes (exclude internal properties)
          for (key in names(value)) {
            if (!startsWith(key, "_")) {
              node_data[[key]] <- value[[key]]
            }
          }

          nodes_map[[node_key]] <- node_data
        } else {
          # Update existing node with any new attributes
          for (key in names(value)) {
            if (
              !startsWith(key, "_") && is.null(nodes_map[[node_key]][[key]])
            ) {
              nodes_map[[node_key]][[key]] <- value[[key]]
            }
          }
        }

        # Store mapping from internal ID to canonical node name (qualified, matches node_data$name)
        node_id_to_name[node_internal_id] <- node_key
      }
    }
  }

  # Convert nodes_map to plain list
  nodes <- unname(nodes_map)

  # Second pass: collect all edges and map from/to to node names
  for (row in all_rows_values) {
    for (i in seq_along(row)) {
      value <- row[[i]]

      # Check if this is an edge (has _label, _src, _dst - note: edge _id is different)
      if (
        is.list(value) &&
          !is.null(value[["_label"]]) &&
          !is.null(value[["_src"]]) &&
          !is.null(value[["_dst"]])
      ) {
        from_id <- internal_id_to_string(value[["_src"]])
        to_id <- internal_id_to_string(value[["_dst"]])

        # Map internal IDs to node names
        from_name <- if (from_id %in% names(node_id_to_name)) {
          node_id_to_name[from_id]
        } else {
          from_id
        }
        to_name <- if (to_id %in% names(node_id_to_name)) {
          node_id_to_name[to_id]
        } else {
          to_id
        }

        edge_data <- list(
          from = from_name,
          to = to_name,
          label = value[["_label"]]
        )

        # Add edge _id if present (for edges it's also a list with offset/table)
        if (!is.null(value[["_id"]])) {
          edge_data$name <- internal_id_to_string(value[["_id"]])
        }

        # Add other attributes (exclude internal properties)
        for (key in names(value)) {
          if (!startsWith(key, "_")) {
            edge_data[[key]] <- value[[key]]
          }
        }

        edges[[length(edges) + 1]] <- edge_data
      }
    }
  }

  result <- list(nodes = nodes, edges = edges)

  # Cache the result for future calls
  assign(qr_hash, result, envir = .kuzu_graph_cache_env)

  result
}

as_data_frame_kuzu_graph <- function(x, ...) {
  graph_data <- extract_graph_data(x)

  # Convert nodes list to data frame
  if (length(graph_data$nodes) > 0) {
    # Find all unique keys across all nodes
    all_node_keys <- unique(unlist(
      lapply(graph_data$nodes, names),
      use.names = FALSE
    ))

    nodes_df <- do.call(
      rbind,
      lapply(graph_data$nodes, function(node) {
        # Create a named vector with all keys, converting NULL to NA
        row_data <- setNames(
          lapply(all_node_keys, function(key) {
            val <- node[[key]]
            if (is.null(val)) NA else val
          }),
          all_node_keys
        )
        # Convert to data frame row
        as.data.frame(row_data, stringsAsFactors = FALSE, check.names = FALSE)
      })
    )

    # Ensure 'name' is first column if it exists
    if ("name" %in% names(nodes_df)) {
      cols <- c("name", setdiff(names(nodes_df), "name"))
      nodes_df <- nodes_df[, cols, drop = FALSE]
    }
  } else {
    nodes_df <- data.frame(stringsAsFactors = FALSE)
  }

  # Convert edges list to data frame
  if (length(graph_data$edges) > 0) {
    # Find all unique keys across all edges
    all_edge_keys <- unique(unlist(
      lapply(graph_data$edges, names),
      use.names = FALSE
    ))

    edges_df <- do.call(
      rbind,
      lapply(graph_data$edges, function(edge) {
        row_data <- setNames(
          lapply(all_edge_keys, function(key) {
            val <- edge[[key]]
            if (is.null(val)) NA else val
          }),
          all_edge_keys
        )
        as.data.frame(row_data, stringsAsFactors = FALSE, check.names = FALSE)
      })
    )
  } else {
    edges_df <- data.frame(stringsAsFactors = FALSE)
  }

  list(nodes = nodes_df, edges = edges_df)
}

#' Convert a Kuzu Query Result to an igraph Object
#'
#' @description
#' Converts a Kuzu query result into an `igraph` graph object.
#'
#' @details
#' This function takes a `kuzu_query_result` object and extracts nodes and edges
#' directly from the query results, then constructs an `igraph` object. It is
#' the final step in the `kuzu_execute -> as_igraph` workflow.
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
  graph_dfs <- as_data_frame_kuzu_graph(query_result)

  if (nrow(graph_dfs$edges) == 0) {
    # No edges - return graph with nodes only, preserving all node attributes
    edge_list <- data.frame(
      from = character(0),
      to = character(0),
      stringsAsFactors = FALSE
    )
    if (nrow(graph_dfs$nodes) > 0) {
      nodes_df <- graph_dfs$nodes
      if (!"name" %in% names(nodes_df)) {
        nodes_df$name <- seq_len(nrow(nodes_df))
      }
    } else {
      nodes_df <- data.frame(name = character(0), stringsAsFactors = FALSE)
    }
    return(igraph::graph_from_data_frame(d = edge_list, vertices = nodes_df))
  }

  # Create edge list with just from/to columns
  edge_list <- graph_dfs$edges[, c("from", "to"), drop = FALSE]

  # Get unique node names from both columns
  all_nodes <- unique(c(
    as.character(edge_list$from),
    as.character(edge_list$to)
  ))

  # Create nodes data frame with at least 'name' column
  nodes_df <- data.frame(name = all_nodes, stringsAsFactors = FALSE)

  # Add additional node attributes if available
  if (nrow(graph_dfs$nodes) > 0) {
    # Create a mapping from node name to other attributes
    # graph_dfs$nodes$name contains the internal node ID (e.g., "0", "1")
    # We need to find the corresponding row for each node
    for (col in setdiff(names(graph_dfs$nodes), "name")) {
      if (!(col %in% names(nodes_df))) {
        nodes_df[[col]] <- sapply(nodes_df$name, function(n) {
          # Find the row in graph_dfs$nodes where name == n
          idx <- which(graph_dfs$nodes$name == n)
          if (length(idx) > 0) {
            val <- graph_dfs$nodes[[col]][idx[1]]
            if (is.null(val)) NA else val
          } else {
            NA
          }
        })
      }
    }
  }

  igraph::graph_from_data_frame(d = edge_list, vertices = nodes_df)
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
  graph_dfs <- as_data_frame_kuzu_graph(query_result)

  # Create edge list - tidygraph/igraph expect from/to columns
  # Must extract ONLY from/to columns, otherwise other columns are misinterpreted
  # as vertex indices
  if (nrow(graph_dfs$edges) > 0) {
    edge_list <- graph_dfs$edges[, c("from", "to"), drop = FALSE]
    # Ensure from/to are character for matching
    edge_list$from <- as.character(edge_list$from)
    edge_list$to <- as.character(edge_list$to)
  } else {
    edge_list <- data.frame(
      from = character(0),
      to = character(0),
      stringsAsFactors = FALSE
    )
  }

  # Get unique node names from edge list (same approach as as_igraph)
  all_nodes <- unique(c(
    as.character(edge_list$from),
    as.character(edge_list$to)
  ))

  # Create nodes data frame - tidygraph needs this to match edge references
  nodes_df <- data.frame(name = all_nodes, stringsAsFactors = FALSE)

  # Add additional node attributes if available
  if (nrow(graph_dfs$nodes) > 0) {
    for (col in setdiff(names(graph_dfs$nodes), "name")) {
      if (!(col %in% names(nodes_df))) {
        nodes_df[[col]] <- sapply(nodes_df$name, function(n) {
          idx <- which(graph_dfs$nodes$name == n)
          if (length(idx) > 0) {
            val <- graph_dfs$nodes[[col]][idx[1]]
            if (is.null(val)) NA else val
          } else {
            NA
          }
        })
      }
    }
  }

  # Use directed = TRUE and node_key = "name" to tell tidygraph to match edges
  tidygraph::tbl_graph(
    nodes = nodes_df,
    edges = edge_list,
    directed = TRUE,
    node_key = "name"
  )
}
