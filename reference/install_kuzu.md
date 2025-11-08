# Install the Kuzu Python package

This function checks if the 'kuzu' Python package is available in the
current reticulate environment. If not, it will ask for permission to
install it using
[`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

## Usage

``` r
install_kuzu()
```

## Examples

``` r
if (FALSE) { # \dontrun{
install_kuzu()
} # }
```
