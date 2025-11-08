# Technical Context: kuzuR

## Technologies Used

-   **R:** The primary language for the package interface.
-   **Python:** The package is a wrapper around the official Python `kuzu` library. It does not interface with the Kuzu C++ core directly.
-   **`reticulate`:** The R package used to bridge the gap between R and Python. It is the core dependency that makes this project possible.
-   **`kuzu` (Python Library):** The official Python client for the Kuzu database. All database operations are passed to this library.
-   **`pandas` (Python Library):** Used for converting query results into a format that can be easily translated into an R `data.frame` or `tibble`.

## Development Setup

A developer working on this package needs:
1.  A working R environment.
2.  A Python installation accessible to `reticulate`.
3.  The `kuzu`, `pandas`, and `networkx` Python packages installed in the environment that `reticulate` uses. The package provides a helper function, `check_kuzu_installation()`, to verify this setup and guide the user.

## The `reticulate` Decision: A Technical Constraint

The choice to use `reticulate` was not arbitrary; it was driven by a fundamental technical roadblock. The initial goal was to create a direct C++ binding using `Rcpp` for maximum performance. However, this was not feasible due to a toolchain incompatibility:

-   The Kuzu C++ library is compiled using **MSVC (Microsoft Visual C++)**.
-   R on Windows, and its associated `RTools`, relies on a **MinGW-based toolchain**.

Attempting to link the MSVC-compiled Kuzu library against an `Rcpp`-based package resulted in compilation and linking errors that could not be resolved. The Python `kuzu` library, however, provides a pre-compiled, stable interface. Therefore, using `reticulate` to wrap the Python library was a pragmatic solution to circumvent the C++ toolchain incompatibility.

## Other Technical Constraints

-   **Performance Overhead:** The `reticulate` bridge introduces a layer of overhead compared to a theoretical native C++ implementation. Data serialization between R and Python is the primary performance consideration.
-   **Python Dependency:** The package is not self-contained. Its functionality is entirely dependent on an external Python environment and the `kuzu`, `pandas`, and `networkx` libraries.
-   **Error Handling:** Errors can originate from R, Python, or the Kuzu database itself. Stack traces can be complex, spanning multiple languages.
-   **`NAMESPACE` Management:** The `NAMESPACE` file is managed automatically by `roxygen2`. It must not be edited manually. All changes to exported functions must be handled via `roxygen2` documentation tags (e.g., `@export`) followed by running `devtools::document()`.

## Resolved `reticulate` Object Round-Trip Issue

During development, a significant `OverflowError: Python int too large to convert to C long` was encountered, which initially pointed towards a C++ toolchain incompatibility. However, the root cause was determined to be an issue with `reticulate`'s handling of Python objects being passed from R back into a subsequent Python call.

**Problem:**
The error occurred when a `kuzu.database.Database` object, created in R, was passed back to Python to create a `kuzu.connection.Connection`. This "round-trip" of the object triggered a low-level introspection error within `reticulate`, leading to the `OverflowError`.

**Resolution:**
The problem was definitively resolved by refactoring the connection logic. The separate `kuzu_database()` and `kuzu_connection()` steps were merged into a single `kuzu_connection(path)` function. This function now performs both the database instantiation and connection creation within a single `reticulate::py_run_string()` call.

**Conclusion:**
By keeping the Python objects within the Python environment and not passing them back and forth with R, the introspection issue is completely avoided. This is the stable and required pattern for this package. The definitive record of this issue and its resolution is documented in `memory-bank/overflow_toolchain_versions.md`.
