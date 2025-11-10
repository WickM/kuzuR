# Strategic Reasoning Bank

This document contains a collection of distilled, generalizable strategic lessons (reasoning units) extracted from past experiences. Each unit provides a title, a high-level description, detailed content explaining the pattern or pitfall, and its source.

---

### 1. Circumventing Foreign Function Interface (FFI) Pitfalls by Minimizing Object Round-Trips

**Description:**
When a cryptic error (e.g., `OverflowError`) occurs in a Foreign Function Interface (FFI) layer like R's `reticulate`, the root cause may not be a direct type mismatch but a subtle issue in the bridge's object introspection or conversion logic. Instead of debugging the FFI layer itself, a more robust solution is to refactor the code to minimize or eliminate the round-trip passing of complex objects between languages.

**Content:**
-   **Problem:** An `OverflowError: Python int too large to convert to C long` occurred when passing a `kuzu` database object from R back to Python via `reticulate`. The error was misleading, suggesting a data type issue.
-   **Incorrect Hypothesis:** The initial assumption was a C++ toolchain or Python version incompatibility causing the integer overflow.
-   **Root Cause:** The actual issue was a `SystemError` in `reticulate`'s ability to correctly introspect the function signatures of the compiled `kuzu` Python library when the object was passed back from R. The FFI bridge itself was the point of failure.
-   **Solution:** The `kuzu_database()` and `kuzu_connection()` functions were merged into a single `kuzu_connection(path)` function. This new function performs both database creation and connection within a single `reticulate::py_run_string()` call. This redesign eliminated the need to pass the Python `database` object from R back to Python, thus avoiding the problematic introspection step and resolving the error.
-   **Strategic Lesson:** When encountering intractable errors at an FFI boundary, consider whether the interaction pattern can be simplified. Consolidating multi-step, cross-language operations into a single, atomic execution within one language's context can often bypass obscure FFI bugs and lead to a more stable and maintainable solution.

**Source:**
`kuzuR` project, `activeContext.md` (Resolution of `OverflowError`).

---

### 2. Overcoming Tool Execution Failures via User-Delegated Execution

**Description:**
When a command-line tool fails to execute due to environment issues (e.g., PATH, shell aliases), delegate the execution to the user. This leverages their configured environment and provides a reliable way to get the necessary output to proceed.

**Content:**
-   **Problem:** The `R CMD check` command failed when executed via the `execute_command` tool. The first attempt failed due to a PowerShell alias issue (`Invoke-History`), and the second attempt using `cmd /c` failed because `R` was not in the system's PATH.
-   **Incorrect Hypothesis:** The command itself was incorrect or malformed.
-   **Root Cause:** The execution environment of the `execute_command` tool was not identical to the user's interactive terminal environment, lacking the necessary PATH configuration or shell setup for the `R` command to be found and executed correctly.
-   **Solution:** After direct execution attempts failed, the `ask_followup_question` tool was used to request that the user run the command in their own terminal/IDE and paste back the output. The user successfully executed the command, providing the necessary feedback to continue the task.
-   **Strategic Lesson:** When direct command execution fails due to environment-specific issues outside of my control, the most efficient path forward is to delegate the execution to the user. This bypasses the environmental mismatch and serves as a reliable fallback for verifying changes or running essential build and check commands.

**Source:**
`kuzuR` project, resolution of `R CMD check` failures.

---

### 3. De-risking `reticulate`-Based R Packages with Cross-Platform CI

**Description:**
For R packages that depend on Python via the `reticulate` bridge, standard CI checks running only on Linux are insufficient. The primary technical risk is the R-to-Python interface, which can have platform-specific failures (especially on Windows due to toolchain differences). A robust CI strategy must validate the `reticulate` bridge on all major operating systems.

**Content:**
-   **Problem:** The `kuzuR` package's CI workflow only ran on `ubuntu-latest`. While it could verify the R code, it failed to test the core dependency: the `reticulate` bridge to the Python `kuzu` library on Windows and macOS, where users are likely to encounter issues.
-   **Incorrect Hypothesis:** A standard `R-CMD-check` on a single OS is sufficient to guarantee package quality.
-   **Root Cause:** The project's `techContext.md` explicitly stated that `reticulate` was chosen to bypass a Windows-specific C++ toolchain incompatibility. By not testing on Windows, the CI process was ignoring the most significant known risk.
-   **Solution:** The GitHub Actions workflow was refactored to use a `strategy: matrix` to run the full test suite on `windows-latest`, `macos-latest`, and `ubuntu-latest`. Additionally, the workflow was modified to explicitly install a specific Python version (`actions/setup-python`) and the required Python packages (`pip install`), creating a predictable and debuggable environment.
-   **Strategic Lesson:** When an R package's core functionality relies on an FFI bridge like `reticulate`, the CI strategy must be designed to de-risk that specific dependency. This involves running tests on a matrix of operating systems to catch platform-specific integration issues and ensuring the foreign language environment (e.g., Python) is explicitly and predictably configured.

**Source:**
`kuzuR` project, refactoring of `.github/workflows/check-package.yaml`.

---

### 4. Ensuring CRAN Compliance for R Packages with Python Dependencies

**Description:**
To successfully submit an R package with Python dependencies to CRAN, the package must be fully functional and pass `R CMD check --as-cran` even in an environment where the specific Python modules are not installed. This requires conditionally disabling any code that calls Python during tests, examples, and vignette builds.

**Content:**
-   **Problem:** The `kuzuR` package failed CRAN submission checks because tests, examples, and vignettes attempted to execute Python code, leading to a `ModuleNotFoundError: No module named 'kuzu'` when the dependency was not present in CRAN's environment.
-   **Incorrect Hypothesis:** A simple `skip_if_not(reticulate::py_available())` is sufficient to handle Python dependencies. This is false, as CRAN's environment may have Python available but will not have the specific required modules.
-   **Root Cause:** The package did not differentiate between the general availability of Python and the specific availability of the required Python module (`kuzu`).
-   **Solution (CRAN Checklist):**
    1.  **Unit Tests (`tests/testthat/`):** Protect each Python-dependent test with a compound check. This ensures tests are skipped on CRAN and also in any local environment missing the module.
        ```r
        testthat::skip_on_cran()
        testthat::skip_if_not(reticulate::py_module_available("your_module"))
        ```
    2.  **Vignettes & README (`.Rmd`):** Use a setup chunk to define a conditional flag, and then use that flag to control the evaluation of Python-dependent code chunks.
        ```r
        # Setup chunk at the beginning of the Rmd
        skip_vignette <- !reticulate::py_module_available("your_module")

        # Python-dependent chunk
        ```{r, eval=!skip_vignette}
        # Code that calls Python
        ```
    3.  **Examples (`.Rd` files / Roxygen):** Wrap any example code that requires the Python module in a `\dontrun{}` block. This prevents CRAN's check from executing the code while still making it available to users in the documentation.
    4.  **Delayed Loading:** Ensure the Python module is imported with `delay_load = TRUE` in the package's `.onLoad` function (typically in `R/zzz.R`) to prevent errors when the package is loaded.
-   **Strategic Lesson:** CRAN compliance for R packages using `reticulate` is not about ensuring the Python dependencies are installed, but about gracefully degrading functionality when they are not. The package must be designed to load, pass checks, and build documentation without ever executing code that requires a specific Python module that CRAN's servers will not have.

**Source:**
`kuzuR` project, resolution of CRAN submission errors.

---

### 5. Handling Misleading `R CMD check` LaTeX Errors for CRAN Submission

**Description:**
When `R CMD check` reports `WARNING` or `ERROR` messages related to PDF manual generation (LaTeX compilation), but the LaTeX log (`kuzuR-manual.log`) indicates successful PDF creation and only minor warnings (e.g., "Overfull \hbox"), it may be a misinterpretation by `R CMD check` rather than a critical compilation failure. In such cases, it's crucial to document the discrepancy and provide evidence of successful PDF generation in the `cran-comments.md` file.

**Content:**
-   **Problem:** `R CMD check` reported "LaTeX errors found" and an `ERROR` during PDF manual generation, even though `kuzuR-manual.log` showed `Output written on Rd2.pdf` and only an "Overfull \hbox" warning. The user was concerned this would block CRAN submission.
-   **Incorrect Hypothesis:** Any `ERROR` or `WARNING` from `R CMD check` related to LaTeX compilation automatically means the PDF manual is not correctly generated or will lead to CRAN rejection.
-   **Root Cause:** `R CMD check` can sometimes be overly sensitive or misinterpret the output/return codes of external compilers like LaTeX. If the LaTeX log confirms successful PDF generation and only non-critical warnings, the `R CMD check` output might be misleading.
-   **Solution:**
    1.  Thoroughly examine the LaTeX log (`kuzuR-manual.log`) for explicit "Error:", "Fatal error:", or "Undefined control sequence" messages.
    2.  If only minor warnings (like "Overfull \hbox") are found and the PDF is successfully generated, document this discrepancy in `cran-comments.md`.
    3.  Clearly state that the PDF manual is indeed produced and that the `R CMD check` messages are believed to be misinterpretations, not actual compilation failures that would prevent CRAN acceptance.
    4.  Ensure any *actual* LaTeX errors (like missing font files) are resolved, as these are critical.
-   **Strategic Lesson:** Do not blindly trust `R CMD check`'s summary of LaTeX errors if the underlying LaTeX log contradicts it. Investigate the detailed LaTeX output. If the PDF is generated and only minor warnings exist, provide a clear explanation in `cran-comments.md` to guide CRAN maintainers. This approach can prevent unnecessary delays or rejections based on misleading check outputs.

**Source:**
`kuzuR` project, resolution of `R CMD check` LaTeX errors for CRAN submission (v0.2.1).
