# System Patterns: kuzuR

## Core Architecture: The Pragmatic `reticulate` Wrapper

The package's architecture is a **`reticulate`-based wrapper for the Python `kuzu` library**. This pattern was not the first choice, but a necessary and pragmatic solution to a fundamental technical challenge: a C++ toolchain incompatibility between the Kuzu library (built with MSVC) and R's toolchain on Windows (MinGW).

This wrapper pattern bypasses the C++ integration problem by leveraging the stable, pre-existing Python interface to Kuzu.

```
+----------------+      +-------------------+      +---------------------------------+      +---------------+
|   R Interface  |----->|  reticulate Bridge  |----->|      Python kuzu Ecosystem      |----->| Kuzu Database |
| (e.g., kuzu.R) |      | (R <-> Python)    |      | (kuzu, pandas, networkx)        |      | (C++ Engine)  |
+----------------+      +-------------------+      +---------------------------------+      +---------------+
```

## Key Pattern Implementations

### 1. R-to-Python Function Mapping

Each primary R function in `kuzuR` (e.g., `kuzu_connection`, `kuzu_execute`) serves as a thin client for its corresponding Python function. The implementation pattern is consistent:
-   An R function is defined.
-   It accepts R arguments.
-   It uses `reticulate::import_main()` to get a handle to the main Python namespace.
-   It injects the R arguments into the Python main namespace.
-   It executes a Python code string using `reticulate::py_run_string()` that calls the target Python function.
-   It retrieves the resulting Python object from the main namespace using `reticulate::py$object_name`.

**Example (`kuzu_connection`):**
```r
kuzu_connection <- function(path) {
  main <- reticulate::import_main()
  main$path <- path
  reticulate::py_run_string("import kuzu; db = kuzu.Database(path); conn = kuzu.Connection(db)", convert = FALSE)
  reticulate::py$conn
}
```

### 2. Chained S3 Methods for Sophisticated Type Coercion

To provide a seamless R experience, the package uses a chain of S3 methods to dispatch on Python object types returned by `reticulate`. This allows standard R functions like `as.data.frame()` or `as_igraph()` to "just work" on Kuzu objects.

This pattern is exemplified by the graph conversion workflow:
1.  A user calls `kuzu_execute()` which returns a `kuzu.query_result.QueryResult` object.
2.  `as_networkx(result)` dispatches on this class, calls the Python `.get_as_networkx()` method, and returns a new object to which we assign the custom S3 class `kuzu_networkx`.
3.  `as.data.frame(networkx_object)` dispatches on the `kuzu_networkx` class. Inside this method, a `reticulate` script leverages the `networkx` and `pandas` Python libraries to create `nodes` and `edges` data frames.
4.  High-level functions like `as_igraph(result)` compose these steps into a simple, user-friendly workflow.

This demonstrates a powerful pattern of creating custom S3 classes for `reticulate` objects to enable clean, R-native conversion workflows.

### 3. Dependency Management via Helper Function

The reliance on Python packages is managed through a dedicated helper function, `install_kuzu()` (located in `R/install.R`). This abstracts the `reticulate::py_install()` process, guiding users to install dependencies into a consistent environment. This is a common pattern for `reticulate`-based packages to simplify setup for non-expert users.
