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
