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
