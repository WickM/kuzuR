# Changelog

## kuzuR 0.1.0

- Initial release of `kuzuR`.
- Provides a wrapper around the Kuzu Python client using `reticulate`.
- Core functionality includes:
  - Connecting to a Kuzu database (`kuzu_database`, `kuzu_connection`).
  - Executing Cypher queries (`kuzu_execute`).
  - Loading data from R data frames (`kuzu_copy_from_df`).
  - Retrieving query results as R data frames or tibbles.
- Integration with R graph libraries:
  - Direct conversion to `igraph` objects with
    [`as_igraph()`](https://wickm.github.io/kuzuR/reference/as_igraph.md).
  - Direct conversion to `tidygraph` objects with
    [`as_tidygraph()`](https://wickm.github.io/kuzuR/reference/as_tidygraph.md).
  - Integration with `g6R` for interactive visualization via `igraph`
    objects.
- Includes a helper function
  [`install_kuzu()`](https://wickm.github.io/kuzuR/reference/install_kuzu.md)
  to manage Python dependencies.
- Added vignettes for installation, usage, and graph library
  integrations.
