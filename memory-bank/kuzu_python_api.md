# kuzu API documentation

## kuzu

Kuzu Python API bindings.

This package provides a Python API for Kuzu graph database management system.

To install the package, run:

    python3 -m pip install kuzu

Example usage:

`import kuzu  db = [kuzu.Database](#Database)("./test") conn = [kuzu.Connection](#Connection)(db)  # Define the schema conn.execute("CREATE NODE TABLE User(name STRING, age INT64, PRIMARY KEY (name))") conn.execute("CREATE NODE TABLE City(name STRING, population INT64, PRIMARY KEY (name))") conn.execute("CREATE REL TABLE Follows(FROM User TO User, since INT64)") conn.execute("CREATE REL TABLE LivesIn(FROM User TO City)")  # Load some data conn.execute('COPY User FROM "user.csv"') conn.execute('COPY City FROM "city.csv"') conn.execute('COPY Follows FROM "follows.csv"') conn.execute('COPY LivesIn FROM "lives-in.csv"')  # Query the data results = conn.execute("MATCH (u:User) RETURN u.name, u.age;") while results.has_next():     print(results.get_next())`

The dataset used in this example can be found [here](https://github.com/kuzudb/kuzu/tree/master/dataset/demo-db/csv).

---
## `AsyncConnection`

AsyncConnection enables asynchronous execution of queries with a pool of connections and threads.

### `AsyncConnection.__init__`

`AsyncConnection( database: Database, max_concurrent_queries: int = 4, max_threads_per_query: int = 0)`

Initialise the async connection.

**Parameters:**

*   **database** (Database): Database to connect to.
*   **max_concurrent_queries** (int): Maximum number of concurrent queries to execute. This corresponds to the number of connections and thread pool size. Default is 4.
*   **max_threads_per_query** (int): Controls the maximum number of threads per connection that can be used to execute one query. Default is 0, which means no limit.

---
## `QueryResult`

QueryResult stores the result of a query execution.

### `QueryResult.get_column_data_types`

`get_column_data_types(self) -> list[str]`

Get the data types of the columns in the query result.

**Returns:**

*   **list**: Data types of the columns in the query result.

### `QueryResult.get_column_names`

`get_column_names(self) -> list[str]`

Get the names of the columns in the query result.

**Returns:**

*   **list**: Names of the columns in the query result.

### `QueryResult.get_schema`

`get_schema(self) -> dict[str, str]`

Get the column schema of the query result.

**Returns:**

*   **dict**: Schema of the query result.
