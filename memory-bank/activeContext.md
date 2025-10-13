# Active Context: kuzuR

## Current Work Focus

The current focus is a full review and synchronization of the memory bank. The goal is to ensure all documents are consistent, accurate, and reflect the latest project state, particularly regarding the resolution of the `OverflowError`.

## Recent Changes

**1. Test Suite Progress:**
-   The `testthat` suite has been significantly updated. Only 5 tests are currently missing.
-   Identified known issues with `Decimal` and `uuid` data types that will require a workaround. These will be addressed in a future development cycle.

**2. Memory Bank Synchronization:**
-   Read all memory bank files to get a comprehensive overview.
-   Identified and corrected inconsistencies related to the now-resolved `OverflowError`.
-   Updated `techContext.md` to accurately describe the root cause of the error (a `reticulate` object round-trip issue, not a toolchain incompatibility).
-   Updated this file (`activeContext.md`) to remove obsolete plans for investigating the `OverflowError`.

**3. R CMD Check Resolution:**
-   Successfully resolved all `ERROR`s, `WARNING`s, and `NOTE`s from `R CMD check --as-cran`.
-   **Dependencies**: Moved `g6R`, `tibble`, and `tidygraph` from `Suggests` to `Imports` in the `DESCRIPTION` file.
-   **Test Failure**: Corrected a file path issue in `tests/testthat/test-kuzu_load_data.R` by replacing `here::here()` with `test_path()` to ensure correct path generation during checks.
-   **Check Notes**:
    -   Added `memory_prompt.md` to `.Rbuildignore`.
    -   Refactored `R/zzz.R` to use `.onAttach` for startup messages instead of `.onLoad`.
    -   Shortened long lines in documentation examples to conform to CRAN standards.

## Next Steps

The immediate next steps involve addressing the remaining items on the CRAN submission checklist and continuing development as outlined:
1.  **`#TODO: Review and Enhance Documentation`**: Ensure all exported functions have complete and runnable examples, and review all documentation for clarity.
2.  **`#TODO: Ensure Package Description Acknowledges Original Authors`**: State clearly in `DESCRIPTION` and `README.md` that `kuzuR` builds upon the work of Kuzu and g6R authors.
3.  **`#TODO: Email Kuzu and G6R Authors`**: Inform them about the `kuzuR` package before CRAN submission.
4.  **`#TODO: Create GitHub Pages for Documentation`**: Set up GitHub Pages for hosting package documentation using `pkgdown` and GitHub Actions.
5.  **`#TODO CSV`**: Document CSV import options (HEADER, DELIM, QUOTE, ESCAPE, SKIP, PARALLEL, IGNORE_ERRORS, auto_detect, sample_size, NULL_STRINGS, Compressed CSV files).
6.  **`#TODO UDF`**: (No specific details provided in the context).
7.  **`#TODO: Resolve R CMD check Note`**: Investigate and resolve the single NOTE from `R CMD check`.
8.  **`#TODO: Handle Python Dependencies Gracefully`**: Review `install_kuzu()` for CRAN compliance.
9.  **`#TODO: Strengthen Testing`**: Review and expand test coverage for all core functionality.

## Resolved Issues

### OverflowError and `reticulate` Introspection

**Status:** RESOLVED

**Summary:**
A persistent `OverflowError` was traced back to a `reticulate` introspection issue when passing Python objects between R and Python. The problem was solved by refactoring the code to eliminate the object round-trip, consolidating database creation and connection into a single operation.

**Strategic Lesson:** A detailed analysis of this issue and its resolution has been distilled into a strategic lesson. See: [`reasoning_bank.md`](./reasoning_bank.md) - *Circumventing Foreign Function Interface (FFI) Pitfalls by Minimizing Object Round-Trips*.

## Kuzu Python API Feature Implementation
Based on the [Kuzu Python API Documentation](./kuzu_python_api.md), the following functions should be reviewed and implemented:
-   **Review for Implementation:**
    -   `AsyncConnection.__init__`: Investigate if an asynchronous connection model is beneficial for the kuzuR package.

### ellmer Graph RAG Tool Implementation Plan (Post-CRAN Submission)
The following plan outlines the implementation of an `ellmer` tool for Graph RAG, to be undertaken after the initial CRAN submission.

**1. Overall Concept: Graph RAG Tool**
The core idea is to create an R function within `kuzuR` that acts as an `ellmer` tool. This tool would allow a large language model (LLM) to:
*   Receive a natural language query from the user.
*   Internally translate that natural language query into a Cypher query relevant to the Kuzu database.
*   Execute the generated Cypher query using `kuzuR`'s existing functionality.
*   Return the results of the query to the LLM in a structured, digestible format.
*   The LLM can then use these results to formulate a comprehensive, natural language response to the user.

**2. Implementation Steps:**
*   **Define the RAG Tool Function (e.g., `kuzu_rag_query`)**:
    *   Create a new R function, perhaps in a new file like `R/rag_tool.R`.
    *   This function would take a natural language query (`user_question`) as its primary argument.
    *   Crucially, it will also accept an optional `ellmer` chat object (`chat_model_for_cypher_gen`) as a parameter. This allows the user to specify the LLM for Cypher generation.
    *   **Defaulting Behavior:** If `chat_model_for_cypher_gen` is not provided, the function will create a default `ellmer` chat object (e.g., `ellmer::chat_openai(model = "gpt-4o")`). This ensures the tool is functional out-of-the-box while allowing customization.
    *   Inside this function, the `chat_model_for_cypher_gen` (either user-provided or default) will be used to translate `user_question` into a Cypher query, potentially providing the Kuzu schema as context to the LLM.
    *   Execute the generated Cypher query using `kuzuR::kuzu_execute()`.
    *   Process the `kuzuR` query results (e.g., convert to a `data.frame` or a summary string) into a format that the `ellmer` chat model can easily interpret.
    *   Return this processed result.

*   **Create `ellmer` Tool Definition**:
    *   Use `ellmer::tool()` to wrap the `kuzu_rag_query` function.
    *   The `ellmer::tool()` definition itself will only expose `user_question` as an argument to the *external* LLM that calls this tool. The `chat_model_for_cypher_gen` parameter is an internal argument to the R function `kuzu_rag_query` and is not part of the `ellmer` tool's schema.
    *   Example structure:
        ```R
        kuzu_rag_tool <- ellmer::tool(
          kuzu_rag_query,
          name = "kuzu_rag_query",
          description = "Queries the Kuzu graph database using a natural language question and returns relevant graph data.",
          arguments = list(
            user_question = ellmer::type_string(
              "The natural language question to ask the Kuzu graph database.",
              required = TRUE
            )
          )
        )
        ```

*   **Integrate with `kuzuR` Package**:
    *   Place the `kuzu_rag_query` function and `kuzu_rag_tool` definition in a new R file, e.g., `R/rag_tool.R`.
    *   Add `ellmer` as a `Suggests` dependency in the `DESCRIPTION` file. This means `ellmer` is an optional dependency for this feature.
    *   Consider adding a helper function (e.g., `kuzu_register_rag_tool(chat_object_to_register_with, chat_model_for_cypher_gen = NULL)`) that users can call. This helper would register `kuzu_rag_tool` with their primary `ellmer` chat object and also allow them to pass the `chat_model_for_cypher_gen` that `kuzu_rag_query` should use internally.

*   **Documentation and Vignette**:
    *   Create a new vignette (e.g., "Graph RAG with kuzuR and ellmer") that demonstrates the end-to-end workflow.
    *   Crucially, this vignette will show how to specify the `chat_model_for_cypher_gen` parameter when setting up the `kuzu_rag_query` function, and also how the default behavior works.

**3. Benefits:**
*   **Natural Language Interface:** Allows users to query the Kuzu database using plain English, lowering the barrier to entry for non-Cypher experts.
*   **Enhanced Data Exploration:** Facilitates more intuitive and dynamic exploration of graph data.
*   **Leverages LLM Intelligence:** Utilizes the LLM's ability to understand context, formulate queries, and synthesize information from graph data.
*   **Extends `kuzuR` Capabilities:** Adds a cutting-edge feature that enhances the value proposition of the `kuzuR` package.

**4. Considerations:**
*   **Complexity of Cypher Generation:** This is the main challenge. The quality of the RAG will heavily depend on how effectively natural language queries are translated into accurate and efficient Cypher.
*   **LLM Costs and Latency:** If an internal LLM call is used for Cypher generation, it will incur additional costs and latency.
*   **Schema Awareness:** The LLM used for Cypher generation will need to be aware of the Kuzu database schema to generate correct queries. This can be provided as part of the prompt.
*   **Security:** Ensure that the generated Cypher queries do not pose security risks (e.g., injection attacks) if user input is directly used in query construction.
