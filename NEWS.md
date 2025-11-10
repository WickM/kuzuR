# kuzuR 0.2.1

*   **Python Integration Improvements**:
    *   Tests requiring the `kuzu` Python module are now skipped on CRAN using `testthat::skip_on_cran()` to ensure smooth CRAN checks.
    *   Enhanced CI workflows (`R-CMD-check.yaml`, `pkgdown.yaml`) explicitly configure Python environments and install necessary dependencies for robust integration testing.
*   **LaTeX Build Fix**:
    *   Resolved a LaTeX error (`! Font T1/pcr/m/n/10=pcrr8t at 10.0pt not loadable: Metric (TFM) file not found.`) that occurred during documentation and vignette building, ensuring all required fonts are available.

# kuzuR 0.2.0

* The `install_kuzu()` helper function has been replaced with `check_kuzu_installation()`. The package no longer installs Python dependencies automatically, instead guiding the user to install them manually for greater environment control. This is a breaking change.
* Fixed a test failure caused by timezone differences.
* Added standard GitHub Actions for R CMD check.

# kuzuR 0.1.0

* Initial release of `kuzuR`.
* Provides a wrapper around the Kuzu Python client using `reticulate`.
* Core functionality includes:
    * Connecting to a Kuzu database (`kuzu_database`, `kuzu_connection`).
    * Executing Cypher queries (`kuzu_execute`).
    * Loading data from R data frames (`kuzu_copy_from_df`).
    * Retrieving query results as R data frames or tibbles.
* Integration with R graph libraries:
    * Direct conversion to `igraph` objects with `as_igraph()`.
    * Direct conversion to `tidygraph` objects with `as_tidygraph()`.
    * Integration with `g6R` for interactive visualization via `igraph` objects.
* Added vignettes for installation, usage, and graph library integrations.
