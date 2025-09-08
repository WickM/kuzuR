#include "kuzuR.h"

//' Create a Kuzu database
//' @param db_path Path to database file, or ":memory:" for in-memory
//' @return External pointer to the database
//' @export
// [[Rcpp::export]]
Rcpp::XPtr<Database> kuzu_database(Rcpp::Nullable<std::string> db_path = R_NilValue) {
    try {
        std::string db_path_str = ":memory:";
        if (db_path.isNotNull()) {
            db_path_str = Rcpp::as<std::string>(db_path);
        }

        SystemConfig systemConfig;
        auto database = std::make_unique<Database>(db_path_str, systemConfig);

        return Rcpp::XPtr<Database>(database.release(), true);

    } catch (const std::exception& e) {
        Rcpp::stop("Failed to create Kuzu database: " + std::string(e.what()));
    }
}

//' Create a connection to a Kuzu database
//' @param database Database object
//' @return External pointer to the connection
//' @export
// [[Rcpp::export]]
Rcpp::XPtr<Connection> kuzu_connection(Rcpp::XPtr<Database> database) {
    try {
        auto connection = std::make_unique<Connection>(database.get());
        return Rcpp::XPtr<Connection>(connection.release(), true);

    } catch (const std::exception& e) {
        Rcpp::stop("Failed to create connection: " + std::string(e.what()));
    }
}

//' Execute a query on a Kuzu database
//' @param connection Connection object
//' @param query Cypher query string
//' @return List with query results
//' @export
// [[Rcpp::export]]
Rcpp::List kuzu_query(Rcpp::XPtr<Connection> connection, std::string query) {
    try {
        auto result = connection->query(query);

        if (!result->isSuccess()) {
            Rcpp::stop("Query failed: " + result->getErrorMessage());
        }

        // Convert to R data structures
        std::vector<std::string> column_names = result->getColumnNames();
        std::vector<Rcpp::CharacterVector> columns(column_names.size());

        while (result->hasNext()) {
            auto row = result->getNext();
            for (size_t i = 0; i < column_names.size(); ++i) {
                columns[i].push_back(row->getValue(i)->toString());
            }
        }

        Rcpp::List result_list;
        for (size_t i = 0; i < column_names.size(); ++i) {
            result_list[column_names[i]] = columns[i];
        }

        return result_list;

    } catch (const std::exception& e) {
        Rcpp::stop("Query execution failed: " + std::string(e.what()));
    }
}
