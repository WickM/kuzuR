## Resubmission

This is a resubmission of `kuzuR` version `0.2.4` with a **deprecation notice**.

### Deprecation Notice

**This package is deprecated and no longer maintained.** 

The Kuzu graph database and its Python client library (`kuzu`) are no longer maintained and no longer available. As a result, `kuzuR` cannot function and will not receive further updates, bug fixes, or security patches.

### Changes in This Submission

- Added deprecation notice to README (both README.Rmd and README.md)
- Changed lifecycle badge from "experimental" to "deprecated"
- Added deprecation message displayed at package startup (in `.onAttach()`)
- Added deprecation notice to NEWS.md
- Fixed DESCRIPTION file to include explicit Author and Maintainer fields for compatibility

### Summary of Previous Changes (v0.2.4)

- Removed pandas and networkx Python package dependencies from user-facing documentation
- Updated installation instructions to only require the `kuzu` Python package
- Fixed test issues with NA value handling in kuzu_copy_from_df
- Fixed test issues with timezone handling and data type mismatches
- GitHub workflows updated to only install required Python dependencies

### R CMD check results

```
Status: 2 WARNINGs, 1 NOTE

* checking files in 'vignettes' ... WARNING
  Files in the 'vignettes' directory but no files in 'inst/doc':
    'getting-started.Rmd', 'graph-integrations.Rmd', 'installation-and-usage.Rmd'
  
* checking package vignettes in 'inst/doc' ... WARNING
  Package vignettes without corresponding single PDF/HTML:
    'getting-started.Rmd', 'graph-integrations.Rmd', 'installation-and-usage.Rmd'
  
* checking package dependencies ... NOTE
  Packages suggested but not available for checking: 'g6R', 'rmarkdown', 'arrow'
```

**Note:** The vignette warnings are expected when building with `--no-build-vignettes`. In a full build environment with rmarkdown installed, vignettes will be properly built. The NOTE about suggested packages is environment-specific and does not affect package functionality.

All tests pass successfully, and the package installs and loads correctly.
