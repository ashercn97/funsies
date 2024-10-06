import db/schema
import gleam/bool
import gleam/int
import gleam/list
import gleam/string
import gleam/dynamic
import gleam/result

pub type QueryBuilder {
  QueryBuilder(
    table: schema.Table,
    select_columns: List(String),
    where_clauses: List(String),
    order_by_clauses: List(String),
  )
}

pub type WhereBuilder {
  WhereBuilder(table: schema.Table, clauses: List(String))
}

// Value type
pub type Value {
  IntValue(Int)
  StringValue(String)
  BoolValue(Bool)
  ErrorValue(String)
}

// Types for equalities
pub type Eq {
  Equals(col: String, value: Value)
}

// Function to turn to clause
fn to_clause_string(eq: Eq) -> String {
  case eq.value {
    StringValue(value) -> eq.col <> " = '" <> value <> "'"
    BoolValue(value) -> eq.col <> " = " <> bool.to_string(value)
    IntValue(value) -> eq.col <> " = " <> int.to_string(value)
    ErrorValue(value) -> panic
  }
}

fn to_clause(table: schema.Table, eq: Eq) {
  let col = list.find(table.columns, fn (c) { c.name == eq.col})
  case is_col_type(table, eq.col, eq.value) {
    True -> to_clause_string(eq)
    False -> "FAILED!"
  }
}

// helper function to check if value is right value
fn is_right_value(value: Value, target: Value) -> Bool{
  case value, target {
    IntValue(_), IntValue(_) -> True
    StringValue(_), StringValue(_) -> True
    BoolValue(_), BoolValue(_) -> True
    _ , _ -> False
  }
}

// Function to type check that values are equal to their column type
fn is_col_type(table: schema.Table, col: String, value: Value) {
  let assert Ok(col) = list.find(table.columns, fn (c) { c.name == col })
  case col {
    schema.StringColumn(_, _) -> is_right_value(value, StringValue("Test"))
    schema.BoolColumn(_) -> is_right_value(value, BoolValue(True))
    schema.ForeignKeyColumn(_, _, _, _) -> is_right_value(value, IntValue(1)) // assumption TODO
    schema.IntColumn(_) -> is_right_value(value, IntValue(1))
    schema.SerialColumn(_) -> is_right_value(value, IntValue(1)) // assumption TODO
  }
}

// Wrap value
fn wrap_value(value: dynamic.Dynamic) -> Value {
  case dynamic.bool(value) {
    Ok(value) -> BoolValue(value)
    Error(_) -> {
      case dynamic.int(value) {
        Ok(value) -> IntValue(value)
        Error(_) -> {
          case dynamic.string(value) {
            Ok(value) -> StringValue(value)
            Error(_) -> ErrorValue("Not a supported value!")
          }
        }
      }
    }
  }
}

pub fn equals(builder: WhereBuilder, col: String, value: v) -> WhereBuilder {
  WhereBuilder(
    table: builder.table,
    clauses: list.append(builder.clauses, [to_clause(builder.table, Equals(col, wrap_value(dynamic.from(value))))]),
  )
}

pub fn ere(table: schema.Table) {
  WhereBuilder(
    table,
    []
  )
}

pub fn to_where(builder: WhereBuilder) {
  builder.clauses
}


// Initialize a new query builder for a table
pub fn new(table: schema.Table) -> QueryBuilder {
  QueryBuilder(table, [], [], [])
}

// Add a select clause (selecting all columns by default)
pub fn select(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    list.map(builder.table.columns, fn (c) {c.name}),
    builder.where_clauses,
    builder.order_by_clauses,
  )
}

// Add a where clause
pub fn wh(builder: QueryBuilder, condition: List(String)) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    list.append(builder.where_clauses, condition),
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
    <> builder.table.name

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
