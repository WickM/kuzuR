# Progress: kuzuR

## What Works

-   **Graph Integrations:** A robust, S3-based system for converting Kuzu query results into R graph objects.
    -   The workflow is `kuzu_execute() -> as_networkx() -> as.data.frame() -> as_igraph()`.
    -   Supports `igraph`, `tidygraph`, and `g6R`.
    -   This feature is now covered by a `testthat` suite.
-   **Core Database Operations:**
    -   Database creation, connection management, query execution (`kuzu_database`, `kuzu_connection`, `kuzu_execute`).
    -   Data loading from `data.frame`s (`kuzu_copy_from_df`).
    -   Result retrieval and conversion to `data.frame` and `tibble`.

## What's Left to Build

-   **Vignettes and Documentation:** A high-priority task is to create a new vignette that demonstrates a complete analysis workflow using the new graph conversion functions. This will significantly improve the package's usability.
-   **Broader Graph Support:** While the core framework is in place, we could add direct conversion wrappers for other popular graph libraries if requested.
-   **Advanced Kuzu Features:** The core package could still be extended to support more advanced Kuzu features (e.g., transaction management, user-defined functions).

## Current Status

The project is at an **alpha** stage. The core functionality is present and is now supported by a comprehensive test suite, significantly increasing its robustness. The next major step towards a beta release is improving user-facing documentation, particularly vignettes.

## Known Issues

-   **OverflowError with `reticulate` and Kuzu:** An `OverflowError: Python int too large to convert to C long` has been reported, occurring during `reticulate`'s interaction with the Kuzu Python library. This is suspected to be due to a C++ toolchain incompatibility between Kuzu's compilation (believed to be C++20) and the Rtools 4.4 environment (GCC 13). Investigation is ongoing, with a proposed solution of upgrading R and Rtools to versions compatible with C++20 (e.g., R 4.5 and Rtools 4.5 with GCC 14).
