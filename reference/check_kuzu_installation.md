# Check for Kuzu Python Dependencies

This function checks if the required Python package (`kuzu`) is
available in the user's `reticulate` environment. If the package is
missing, it provides a clear, actionable message guiding the user on how
to install it manually.

## Usage

``` r
check_kuzu_installation()
```

## Value

`NULL` invisibly. The function is called for its side effect of checking
dependencies and printing messages.

## Examples

``` r
# \donttest{
check_kuzu_installation()
#> Error: The 'kuzu' Python package is not installed.
#> To install it, please run the following command in your R console:
#> reticulate::py_install('kuzu', pip = TRUE)
# }
```
