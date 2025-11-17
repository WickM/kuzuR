# Check for Kuzu Python Dependencies

This function checks if the required Python packages (`kuzu`, `pandas`,
`networkx`) are available in the user's `reticulate` environment. If any
packages are missing, it provides a clear, actionable message guiding
the user on how to install them manually.

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
#> Error: The following required Python packages are not installed: kuzu, pandas, networkx 
#> To install them, please run the following command in your R console: 
#> reticulate::py_install(c("kuzu", "pandas", "networkx"), pip = TRUE)
# }
```
