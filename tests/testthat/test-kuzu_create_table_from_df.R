# Test suite for kuzu_create_table_from_df

test_that("kuzu_create_table_from_df creates a table with correct schema", {
  conn <- kuzu_connection(":memory:")
  
  test_df <- data.frame(
    name = c("Alice", "Bob"),
    age = c(25L, 30L),
    height = c(1.75, 1.80),
    is_student = c(TRUE, FALSE),
    birth_date = as.Date(c("1999-01-01", "1994-05-15"))
  )
  
  kuzu_create_table_from_df(conn, test_df, "Person", primary_key = "name")
  kuzu_copy_from_df(conn, test_df, "Person")
  
  result <- kuzu_execute(conn, "MATCH (p:Person) RETURN p.name, p.age, p.height, p.is_student, p.birth_date")
  schema <- kuzu_get_schema(result)
  
  # The order of columns is not guaranteed, so we check for names and types separately
  expect_equal(sort(names(schema)), sort(c("p.name", "p.age", "p.height", "p.is_student", "p.birth_date")))
  expect_equal(schema$`p.name`, "STRING")
  expect_equal(schema$`p.age`, "INT64")
  expect_equal(schema$`p.height`, "DOUBLE")
  expect_equal(schema$`p.is_student`, "BOOL")
  expect_equal(schema$`p.birth_date`, "DATE")
})

test_that("kuzu_create_table_from_df handles unsupported types", {
  conn <- kuzu_connection(":memory:")
  
  test_df <- data.frame(
    id = 1:2,
    category = as.factor(c("A", "B"))
  )
  
  expect_warning(
    kuzu_create_table_from_df(conn, test_df, "Categories", primary_key = "id"),
    "Coercing 'factor' to 'STRING'."
  )
  
  kuzu_copy_from_df(conn, test_df, "Categories")
  
  result <- kuzu_execute(conn, "MATCH (c:Categories) RETURN c.id, c.category")
  schema <- kuzu_get_schema(result)
  
  expect_equal(schema$`c.category`, "STRING")
})

test_that("kuzu_create_table_from_df handles NA values", {
  conn <- kuzu_connection(":memory:")
  
  test_df <- data.frame(
    id = 1:2,
    value = c(10.5, NA_real_)
  )
  
  kuzu_create_table_from_df(conn, test_df, "Measurements", primary_key = "id")
  kuzu_copy_from_df(conn, test_df, "Measurements")
  
  result <- kuzu_execute(conn, "MATCH (m:Measurements) RETURN m.id, m.value")
  schema <- kuzu_get_schema(result)
  
  expect_equal(schema$`m.value`, "DOUBLE")
})

test_that("kuzu_create_table_from_df stops if primary key is invalid", {
  conn <- kuzu_connection(":memory:")
  
  test_df <- data.frame(id = 1:2, value = c("a", "b"))
  
  expect_error(
    kuzu_create_table_from_df(conn, test_df, "InvalidPK", primary_key = "non_existent_col"),
    "Primary key 'non_existent_col' not found in data frame."
  )
})
