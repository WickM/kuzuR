Sys.setenv(NOT_CRAN = "true")
library(devtools)
load_all('.')

# Test
conn <- kuzu_connection(':memory:')
kuzu_execute(conn, 'CREATE NODE TABLE Person(name STRING, age INT64, PRIMARY KEY(name))')
kuzu_execute(conn, 'CREATE REL TABLE Knows(FROM Person TO Person, since INT64)')
kuzu_execute(conn, "CREATE (p:Person {name: 'Alice', age: 30})")
kuzu_execute(conn, "CREATE (p:Person {name: 'Bob', age: 40})")
kuzu_execute(conn, "MATCH (a:Person), (b:Person) WHERE a.name = 'Alice' AND b.name = 'Bob' CREATE (a)-[:Knows {since: 2021}]->(b)")

query_res <- kuzu_execute(conn, 'MATCH (p:Person)-[k:Knows]->(q:Person) RETURN p, k, q')

# Debug: trace through extract_graph_data
cat("=== DEBUG: get_all() result ===\n")
all_rows <- query_res$get_all()
cat("Length:", length(all_rows), "\n")
print(all_rows)

cat("\n=== DEBUG: kuzu_get_column_names ===\n")
col_names <- query_res$get_column_names()
print(col_names)

cat("\n=== DEBUG: kuzu_get_all ===\n")
all_kuzu <- kuzu_get_all(query_res)
print(all_kuzu)

cat("\n=== DEBUG: as_data_frame ===\n")
df <- as.data.frame(query_res)
print(df)

cat("\n=== DEBUG: as_igraph ===\n")
g <- as_igraph(query_res)
print(g)
