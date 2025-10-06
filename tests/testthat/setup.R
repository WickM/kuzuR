# # Load the kuzuR package so its functions are available to the tests
# # Use devtools::load_all() to simulate package loading in a clean environment
# if (requireNamespace("devtools", quietly = TRUE)) {
#   devtools::load_all()
# } else {
#   warning("devtools not found. Package functions may not be available to tests.")
# }

# # This file is run before any tests are executed.
# # It ensures that reticulate is initialized with the correct Python environment.
# tryCatch({
#   # Specify the virtual environment that should be used for testing.
#   # This is typically created by install_kuzu() or reticulate's py_install().
#   #reticulate::use_virtualenv("r-reticulate", required = TRUE)
# }, error = function(e) {
#   warning("Could not activate 'r-reticulate' virtualenv. Tests might fail if Python dependencies are not in the default environment.")
# })
