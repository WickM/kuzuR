# Getting Started with kuzuR

## Introduction

Welcome to `kuzuR`! This guide will walk you through the basic steps to
get started with `kuzuR`, from installation to running your first query.

## Installation

First, ensure you have the `kuzuR` package installed from GitHub. You
will also need `reticulate` to manage the Python environment.

Development Version

``` r
remotes::install_github("WickM/kuzuR")
```

Cran Version

``` r
install.packages("kuzuR")
```

## Basic Usage

### 1. Create a Connection

The first step is to create a connection to a Kuzu database. You can
create an in-memory database or connect to a database on disk.

``` r
library(kuzuR)

# Create an in-memory database connection
con <- kuzu_connection(":memory:")
```

### 2. Create a Schema

Next, define your graph schema using Cypher queries. Let’s create a
simple schema with `Person` nodes and `Knows` relationships.

``` r
kuzu_execute(con, paste("CREATE NODE TABLE Person(name STRING, age INT64,",
                        "PRIMARY KEY (name))"))
#> <kuzu.query_result.QueryResult object at 0x7f0f9a2b0890>
kuzu_execute(con, "CREATE REL TABLE Knows(FROM Person TO Person, since INT64)")
#> <kuzu.query_result.QueryResult object at 0x7f0f9a2e0110>
```

### 3. Load Data

You can load data from R data frames directly into your Kuzu database.

``` r
# Create a data frame of persons
persons_df <- data.frame(
  name = c("Alice", "Bob", "Carol"),
  age = c(35, 45, 25)
)

# Create a data frame of relationships
knows_df <- data.frame(
  from_person = c("Alice", "Bob"),
  to_person = c("Bob", "Carol"),
  since = c(2010, 2015)
)

# Load data into Kuzu
kuzu_copy_from_df(con, persons_df, "Person")
kuzu_copy_from_df(con, knows_df, "Knows")
```

### 4. Query Data

Finally, you can query your graph using Cypher and retrieve the results
as an R data frame.

``` r
# Execute a query
result <- kuzu_execute(con, paste("MATCH (a:Person)-[k:Knows]->(b:Person)",
                                  "RETURN a.name, b.name, k.since"))

# Convert the result to a data frame
df <- as.data.frame(result)
print(df)
#>   a.name b.name k.since
#> 1  Alice    Bob    2010
#> 2    Bob  Carol    2015
```

This concludes the “Getting Started” guide. For more advanced topics,
please see the other articles and the function reference.
