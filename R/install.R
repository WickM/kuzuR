#' Install the Kuzu Python package
#'
#' This function checks if the 'kuzu' Python package is available in the current
#' reticulate environment. If not, it will ask for permission to install it
#' using `reticulate::py_install()`.
#'
#' @export
#' @examples
#' \dontrun{
#' install_kuzu()
#' }
install_kuzu <- function() {
  pkgs <- c("kuzu", "pandas", "networkx")
  installed_status <- sapply(pkgs, reticulate::py_module_available)
  
  if (all(installed_status)) {
    message("The 'kuzu', 'pandas', and 'networkx' Python packages are already installed and available.")
    return(invisible(NULL))
  }

  missing_pkgs <- names(installed_status[!installed_status])
  message(paste("The following required Python packages are not installed:", paste(missing_pkgs, collapse = ", ")))
  
  if (interactive()) {
    question <- "Would you like to install them now? (This will use reticulate::py_install)"
    if (utils::askYesNo(question, default = TRUE)) {
      # Ask user if they want to create a new environment or use an existing one
      env_choice <- readline(prompt="Install into a new environment? (y/n, default is 'n' for current/specified env): ")
      
      if (tolower(env_choice) == "y") {
        new_env_name <- readline(prompt="Enter the name for the new environment: ")
        if (new_env_name != "") {
          reticulate::py_install(pkgs, pip = TRUE, envname = new_env_name, create_env = TRUE)
        } else {
          message("New environment name cannot be empty. Installation cancelled.")
        }
      } else {
        # User chose not to create a new environment, prompt for existing env name or use default
        existing_env_name <- readline(prompt="Enter the name of the existing environment to use (leave blank for default): ")
        if (existing_env_name != "") {
          reticulate::py_install(pkgs, pip = TRUE, envname = existing_env_name)
        } else {
          # Use default environment if blank is provided
          reticulate::py_install(pkgs, pip = TRUE) 
        }
      }
    } else {
      message("Installation cancelled by user.")
    }
  } else {
    message("To install the required packages, please run `kuzuR::install_kuzu()` in an interactive R session.")
  }
  
  invisible(NULL)
}
