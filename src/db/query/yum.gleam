import gleam/list
import gleam/string

pub type QueryBuilder {
  QueryBuilder(
    table: String,
    select_columns: List(String),
    where_clauses: List(String),
    order_by_clauses: List(String),
  )
}

// Initialize a new query builder for a table
pub fn new(table: String) -> QueryBuilder {
  QueryBuilder(table, [], [], [])
}

// Add a select clause (selecting all columns by default)
pub fn select(builder: QueryBuilder, columns: List(String)) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    columns,
    builder.where_clauses,
    builder.order_by_clauses,
  )
}

// Add a where clause
pub fn where(builder: QueryBuilder, condition: String) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    list.append(builder.where_clauses, [condition]),
    builder.order_by_clauses,
  )
}

// Add an order by clause
pub fn order_by(
  builder: QueryBuilder,
  column: String,
  direction: String,
) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    builder.where_clauses,
    list.append(builder.order_by_clauses, [column <> " " <> direction]),
  )
}

// Build the final SQL query
pub fn to_sql(builder: QueryBuilder) -> String {
  let base_query =
    "SELECT "
    <> string.join(builder.select_columns, ", ")
    <> " FROM "
    <> builder.table

  let where_sql = case builder.where_clauses {
    [] -> ""
    clauses -> " WHERE " <> string.join(clauses, " AND ")
  }

  let order_by_sql = case builder.order_by_clauses {
    [] -> ""
    clauses -> " ORDER BY " <> string.join(clauses, ", ")
  }

  base_query <> where_sql <> order_by_sql <> ";"
}
