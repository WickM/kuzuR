# Active Context: kuzuR

## Current Work Focus

The primary focus of this session was to fix a series of test failures and significantly improve the overall test coverage of the package.

## Recent Changes

**1. Test Suite Bug Fixes**
-   **Corrected Data Retrieval:** Fixed a bug in `kuzu_get_all()`, `kuzu_get_n()`, and `kuzu_get_next()` where the functions were returning unnamed lists instead of named lists, causing test failures. The functions now correctly associate column names with the returned data.
-   **Handled Iterator Exhaustion:** Added a check in `kuzu_get_next()` to prevent a `RuntimeError` that occurred when the function was called on an exhausted query result iterator.

**2. Test Coverage Maximization**
-   **Increased Coverage to 100%:** Wrote a comprehensive suite of new tests to bring the coverage of `R/kuzu.R`, `R/install.R`, `R/zzz.R`, and `R/graph.R` to 100%.
-   **Error Path Testing:** The new tests specifically target error conditions, such as when required R packages (`tibble`) or Python modules (`pandas`) are not installed.
-   **Mocking for Robustness:** Used the `mockery` package to simulate different environments and user inputs, allowing for thorough testing of installation logic (`install_kuzu`) and package loading hooks (`.onLoad`) without side effects.
-   **New Test File:** Created `tests/testthat/test-utils.R` to house tests for utility functions, keeping the test suite organized.
-   **Iterative Debugging:** Debugged and corrected a series of issues within the new test suite itself, including problems with mock object configuration and testing locked bindings in the `.onLoad` function.

## Next Steps

### CRAN Submission Checklist
The following tasks must be completed before the package is ready for submission to CRAN:

1.  **#TODO: Pass `R CMD check --as-cran`:**
    -   Run the check locally and resolve all errors, warnings, and notes.
    -   Pay special attention to undeclared dependencies, documentation mismatches, and example errors.

2.  **#TODO: Create "Installation and Basic Usage" Vignette:**
    -   This vignette should cover how to install the `kuzuR` package and its Python dependencies.
    -   It should also demonstrate basic usage, including connecting to a database, creating a schema, loading data, and executing simple Cypher queries, similar to the Python examples in the Kuzu documentation.

3.  **#TODO: Create "Graph Library Integrations" Vignette:**
    -   This vignette should showcase how to convert Kuzu query results into different R graph library objects (e.g., `igraph`, `tidygraph`).
    -   It should provide examples for each supported library, demonstrating the conversion process and basic graph analysis.

4.  **#TODO: Create "g6R Visualization" Vignette:**
    -   This vignette should specifically focus on using `g6R` for interactive visualization of Kuzu graph data.
    -   It should provide detailed examples of converting Kuzu results to `g6R` objects and customizing their appearance.

5.  **#TODO: Update `DESCRIPTION` File:**
    -   Add `URL` and `BugReports` fields, pointing to the GitHub repository.
    -   Review and clean up the `Imports` and `Suggests` fields. The `dplyr` dependency appears to be unused and should be removed.

6.  **#TODO: Write a `NEWS.md` File:**
    -   Create a `NEWS.md` file to document changes in the upcoming `0.1.0` release.

7.  **#TODO: Review and Enhance Documentation:**
    -   Ensure all exported functions have complete and runnable examples in their `@examples` tag.
    -   Review all function documentation for clarity and accuracy.

8.  **#TODO: Verify `LICENSE` File:**
    -   Confirm that the `LICENSE` file contains the full, standard MIT license text.

9.  **#TODO: Ensure Package Description Acknowledges Original Authors:**
    -   Clearly state in the `DESCRIPTION` file and `README.md` that the major work on Kuzu and G6R was done by their respective authors, and `kuzuR` stands on their shoulders.

10. **#TODO: Create Hex Sticker for the Package:**
    -   Design and create a hex sticker for `kuzuR` before CRAN submission.

11. **#TODO: Email Kuzu and g6R Authors:**
    -   After implementing the mentioned features and before CRAN submission, email the authors of Kuzu and g6R to inform them about the `kuzuR` package and ask them to consider mentioning it.

12. **#TODO: Create GitHub Pages for Documentation:**
    -   Set up GitHub Pages to host the package documentation, similar to `ggplot2.tidyverse.org`. This will involve configuring `pkgdown` and GitHub Actions for automatic deployment.

### Kuzu Python API Feature Implementation
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

## Important Patterns and Preferences

-   **Task Tracking:** When outlining tasks, always prepend them with "#TODO:" for clear visibility and tracking.
-   **Problem-Solving:** When encountering a persistent bug or a lack of clarity about an external library's object structure, do not guess repeatedly. After two failed attempts, prioritize asking the user for help, for example by requesting the output of a command like `str()` to reveal an object's structure.
-   **Function Design:** Focus on function separation. Avoid creating "do-everything" functions. Instead, compose small, single-purpose functions into a larger workflow. This promotes modularity, reusability, and easier testing.
-   **Architecture:** The project follows a `reticulate`-based wrapper pattern. All new R functions that interface with the database should follow this established pattern of calling Python via `py_run_string`.
-   **Documentation:** Functions must be documented with high-quality `roxygen2`-style comments. Descriptions should be clear, detailed, and adhere to R's documentation best practices. Every exported function should include a runnable example in its `@examples` tag.
-   **User Experience:** The primary goal is a seamless R user experience. Abstractions should hide Python-specific details wherever possible. S3 methods should be used for type conversion to familiar R objects (`data.frame`, `tibble`).

### Interactive Kuzu Graph Explorer with Shiny and Natural Language Querying (Post-CRAN Submission)
The following plan outlines the implementation of an interactive R Shiny application for exploring and manipulating Kuzu graph data, including natural language querying capabilities via `ellmer`. This will be undertaken after the initial CRAN submission.

**1. Overall Concept:**
The goal is to create a user-friendly web interface within `kuzuR` that allows users to:
*   Connect to a Kuzu database.
*   Visualize graph data (nodes and edges) interactively using `g6R`.
*   Perform dynamic searches and filtering on the graph.
*   Input natural language queries, which will be translated to Cypher via the `ellmer` RAG tool and executed against the Kuzu database, with results displayed in the graph.
*   Potentially edit graph data (add/remove nodes/edges, modify properties) through the UI.

**2. Key Components and Implementation Ideas:**

*   **Shiny Application Structure:**
    *   The application would reside in a new directory, e.g., `inst/shinyapp/`, within the `kuzuR` package. This allows users to launch it easily via `shiny::runApp(system.file("shinyapp", package = "kuzuR"))`.
    *   **`ui.R` (User Interface):**
        *   Utilize `bslib::page_fluid()` or `bslib::page_navbar()` with a `bs_theme(version = 5)` for a modern Bootstrap 5 theme.
        *   **Database Connection Panel:** Input fields for the Kuzu database path.
        *   **Natural Language Query Input:** A prominent text area or input box where users can type natural language questions (e.g., "Show me all persons over 30 who are friends with John."). Include a submit button.
        *   **Graph Visualization Output:** A dedicated area to display the interactive graph using `g6R`.
        *   **Search/Filter Controls (Complementary to NLQ):** Text input for keyword search, dropdowns for selecting node/edge labels, and input fields for property-based filtering.
        *   **Cypher Query Console (Optional):** An input box for users to type and execute custom Cypher queries, with an output area for results (e.g., the raw Cypher generated by the NLQ, or direct user input).
        *   **Graph Manipulation Controls (Optional, Advanced):** Buttons for adding nodes/edges, editing properties, or deleting elements.
    *   **`server.R` (Server Logic):**
        *   **Database Connection Management:** Reactive logic to establish and manage the `kuzuR` connection.
        *   **Natural Language Query Processing:**
            *   Observe the natural language query input and its submit button.
            *   When a query is submitted, call the `kuzu_rag_query` function (the `ellmer` tool) with the user's natural language input.
            *   Pass the user-specified `ellmer` chat object (or the default one) to `kuzu_rag_query` for internal Cypher generation.
            *   The `kuzu_rag_query` function will return the graph data (or a summary) based on the generated Cypher.
        *   **Data Fetching:** Functions to execute Cypher queries (either generated by the RAG tool, from direct Cypher input, or from search/filter controls) to retrieve graph data.
        *   **Data Transformation:** Convert `kuzuR` query results into `g6R` compatible formats (e.g., using `as_g6R()`).
        *   **Visualization Rendering:** Render the interactive graph using `g6R`, updating reactively based on NLQ results or other filters.
        *   **Search Logic:** Dynamically construct and execute Cypher queries based on user input in the search/filter controls.
        *   **Editing Logic (Optional):** Translate UI actions into appropriate Cypher `CREATE`, `SET`, or `DELETE` statements.
        *   **Error Handling:** Implement robust error handling for database operations and user input, displaying messages to the user in the Shiny app.

*   **Graph Visualization Library:**
    *   **`g6R`**: Confirmed as the chosen library for interactive graph visualization.

*   **Search and Filtering Functionality:** (Will be complemented by the Natural Language Query input.)

*   **Graph Editing Functionality (Consider as a later phase due to complexity):** (No change)

*   **Integration with `kuzuR` Package:**
    *   The Shiny application will be a consumer of `kuzuR`'s core functions, including the `kuzu_rag_query` function (the `ellmer` tool).
    *   `shiny`, `bslib`, `g6R`, and `ellmer` should all be added as `Suggests` dependencies in the `DESCRIPTION` file.
    *   A new R function, `kuzu_launch_explorer()`, will be added to `kuzuR` to provide a convenient way to launch the Shiny app. This function will now accept an optional `ellmer_chat_object` argument:
        ```R
        kuzu_launch_explorer <- function(db_path = NULL, ellmer_chat_object = NULL) {
          # ... (Shiny app setup) ...
          # Pass ellmer_chat_object to the server logic,
          # which then passes it to kuzu_rag_query
          # If ellmer_chat_object is NULL, kuzu_rag_query will use its default.
        }
        ```
    *   Within the Shiny app's `server.R`, the `ellmer_chat_object` passed to `kuzu_launch_explorer` will be made available to the reactive context (e.g., via `options()` or a reactive value) and then used when calling the `kuzu_rag_query` function for Cypher generation.

**3. Benefits:**
*   **Enhanced User Accessibility:** Provides a visual, interactive way to explore Kuzu graphs without needing deep Cypher knowledge.
*   **Rapid Prototyping & Exploration:** Facilitates quick understanding and analysis of graph data.
*   **Demonstrates `kuzuR` Capabilities:** Showcases the power of `kuzuR` in a compelling, interactive format.
*   **Educational Tool:** Can serve as a learning tool for understanding graph structures and Cypher queries.

**4. Considerations:**
*   **Performance:** For very large graphs, rendering and interactivity in Shiny can become a bottleneck. Strategies like pagination, sampling, or server-side rendering might be needed.
*   **Complexity of Editing:** Implementing robust and safe graph editing through a UI is challenging and requires careful validation and error handling.
*   **Dependency Management:** Ensure `shiny`, `bslib`, `g6R`, and `ellmer` are properly handled as `Suggests` dependencies.
*   **Security:** If editing is enabled, ensure proper input sanitization to prevent Cypher injection vulnerabilities.
