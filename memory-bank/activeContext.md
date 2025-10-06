# Active Context: kuzuR

## Current Work Focus

The primary focus of this session was to improve the documentation for the data loading functions in `R/kuz_load_data.R`, specifically addressing the `kuzu_merge_df` function and ensuring all provided links were correctly integrated. Additionally, syntax errors within the file were identified and corrected.

## Recent Changes

**1. Documentation Enhancement for Data Loading Functions:**
-   **`kuzu_copy_from_df`:** Updated documentation to include details on handling relationship tables and corrected example code for argument order.
-   **`kuzu_copy_from_csv`, `kuzu_copy_from_json`, `kuzu_copy_from_parquet`:** Ensured documentation included relevant links and notes on their wrapper functionality.
-   **`kuzu_merge_df`:** Significantly enhanced documentation to:
    -   Clarify its purpose and reliance on Python's reticulate.
    -   Provide a detailed note on the syntactically incorrect query and the need for further development.
    -   Include an example of a hypothetical merge query structure, specifying the expected format for the `merge_query` parameter.
    -   Add a second example demonstrating a different merge query structure.
-   **General Documentation:** Incorporated all provided Kuzu import links into the respective function documentation.

**2. File Integrity and Syntax Correction:**
-   **`R/kuz_load_data.R`:** Addressed and corrected several syntax errors identified in the file, ensuring the R code is valid.

**3. Memory Bank Update:**
-   Updated `memory-bank/activeContext.md` to reflect the completion of the documentation task and the associated file updates.

## Next Steps

The immediate next steps involve addressing the remaining items on the CRAN submission checklist, which include:
1.  **#TODO: Write Tests for import functions:** Ensure test coverage for import functions is near 100%.
2.  **#TODO: Pass `R CMD check --as-cran`:** Run the check locally and resolve all errors, warnings, and notes.
3.  **#TODO: Create "g6R Visualization" Vignette:** Focus on using `g6R` for interactive visualization of Kuzu graph data.
4.  **#TODO: Update `DESCRIPTION` File:** Add `URL` and `BugReports` fields, and clean up `Imports` and `Suggests`.
5.  **#TODO: Write a `NEWS.md` File:** Document changes for the `0.1.0` release.
6.  **#TODO: Review and Enhance Documentation:** Ensure all exported functions have complete and runnable examples, and review all documentation for clarity.
7.  **#TODO: Verify `LICENSE` File:** Confirm the `LICENSE` file contains the full MIT license text.
8.  **#TODO: Ensure Package Description Acknowledges Original Authors:** State clearly in `DESCRIPTION` and `README.md` that `kuzuR` builds upon the work of Kuzu and g6R authors.
9.  **#TODO: Email Kuzu and g6R Authors:** Inform them about the `kuzuR` package before CRAN submission.
10. **#TODO: Create GitHub Pages for Documentation:** Set up GitHub Pages for hosting package documentation using `pkgdown` and GitHub Actions.
11. **#TODO CSV:** Document CSV import options (HEADER, DELIM, QUOTE, ESCAPE, SKIP, PARALLEL, IGNORE_ERRORS, auto_detect, sample_size, NULL_STRINGS, Compressed CSV files).
12. **#TODO UDF:** (No specific details provided in the context).

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
