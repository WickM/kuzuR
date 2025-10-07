# Product Context: kuzuR

## The "Why"

The `kuzuR` package exists to bridge the gap between the R statistical programming environment and the high-performance Kuzu graph database. R is a dominant language for data analysis, but it lacks native interfaces to many modern database systems, particularly graph databases. This forces R users to adopt complex workflows, switch languages, or export data to interact with graph data, creating friction and inefficiency.

## Problem Solved

`kuzuR` solves the problem of accessing and manipulating a Kuzu graph database directly from R. It eliminates the need for intermediate tools or languages, providing a streamlined and idiomatic R experience for graph database operations.

## How It Should Work

From a user's perspective, the workflow should be simple and intuitive:
1.  **Install the package:** A straightforward installation process, ideally from CRAN or GitHub.
2.  **Load the library:** `library(kuzuR)`
3.  **Establish a connection:** Create a connection to a database by specifying a path. This single step handles both database creation (if it doesn't exist) and the connection, e.g., `con <- kuzu_connection("path/to/db")`.
4.  **Execute queries:** Run Cypher queries using a simple function, e.g., `result <- kuzu_execute(con, "MATCH (n) RETURN n")`.
5.  **Retrieve data:** Fetch results into standard R data structures like a `data.frame` or `tibble` using `as.data.frame()`.
6.  **Convert to graphs:** Convert a query result that returns a graph structure directly into an `igraph` or `tidygraph` object for advanced analysis (e.g., `graph <- as_igraph(result)`).

## User Experience Goals

-   **Seamless Integration:** The package should feel "native" to R. Functions should follow common R conventions, and data should be returned in familiar formats (`data.frame`, `igraph`, `tbl_graph`).
-   **Minimal Friction:** Users should not need to understand the intricacies of the underlying database connection. The interface should abstract away unnecessary complexity.
-   **Performance:** While being a wrapper, the package should be performant enough for interactive data analysis and typical workloads.
