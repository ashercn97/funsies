import db/schema
import gleam/bool
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option
import gleam/queue
import gleam/string

pub type QueryBuilder {
  QueryBuilder(
    table: schema.Table,
    select_columns: List(String),
    where_clauses: List(Eq),
    order_by_clauses: List(String),
    insert_columns: List(String),
    // New field for insert columns
    insert_values: List(Value),
    // New field for insert values
  )
}

pub type WhereBuilder {
  WhereBuilder(table: schema.Table, clauses: List(Eq))
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
  Not(Eq)
  Or(Eq, Eq)
  And(Eq, Eq)
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

// Function to turn to clause
fn to_string(value: Value) -> String {
  case value {
    StringValue(value) -> "'" <> value <> "'"
    IntValue(value) -> int.to_string(value)
    BoolValue(value) -> bool.to_string(value)
    ErrorValue(value) -> panic
  }
}

fn is_right_value(value: Value, target: Value) -> Bool {
  case value, target {
    IntValue(_), IntValue(_) -> True
    StringValue(_), StringValue(_) -> True
    BoolValue(_), BoolValue(_) -> True
    _, _ -> False
  }
}

fn is_col_type(table: schema.Table, col: String, value: Value) -> Bool {
  let assert Ok(col) = list.find(table.columns, fn(c) { c.name == col })
  case col {
    schema.StringColumn(_, _) -> is_right_value(value, StringValue("Test"))
    schema.BoolColumn(_) -> is_right_value(value, BoolValue(True))
    schema.ForeignKeyColumn(_, _, _, _) -> is_right_value(value, IntValue(1))
    // assumption TODO
    schema.IntColumn(_) -> is_right_value(value, IntValue(1))
    schema.SerialColumn(_) -> is_right_value(value, IntValue(1))
    // assumption TODO
  }
}

pub fn equals(builder: WhereBuilder, col: String, value: v) -> WhereBuilder {
  let wrapped_value = wrap_value(dynamic.from(value))
  case is_col_type(builder.table, col, wrapped_value) {
    True ->
      WhereBuilder(
        builder.table,
        list.append(builder.clauses, [Equals(col, wrapped_value)]),
      )
    False ->
      WhereBuilder(
        builder.table,
        list.append(builder.clauses, [Equals(col, ErrorValue("Type mismatch"))]),
      )
  }
}

pub fn not(builder: WhereBuilder) -> WhereBuilder {
  case queue.pop_back(queue.from_list(builder.clauses)) {
    Ok(#(eq, rest)) ->
      WhereBuilder(builder.table, list.append(queue.to_list(rest), [Not(eq)]))
    _ -> builder
  }
}

pub fn or(builder: WhereBuilder) -> WhereBuilder {
  case queue.pop_back(queue.from_list(builder.clauses)) {
    Ok(#(eq1, rest1)) ->
      case queue.pop_back(rest1) {
        Ok(#(eq2, rest2)) ->
          WhereBuilder(
            builder.table,
            list.append(queue.to_list(rest2), [Or(eq1, eq2)]),
          )
        _ -> builder
      }
    _ -> builder
  }
}

pub fn and(builder: WhereBuilder) -> WhereBuilder {
  case queue.pop_back(queue.from_list(builder.clauses)) {
    Ok(#(eq1, rest1)) ->
      case queue.pop_back(rest1) {
        Ok(#(eq2, rest2)) ->
          WhereBuilder(
            builder.table,
            list.append(queue.to_list(rest2), [And(eq1, eq2)]),
          )
        _ -> builder
      }
    _ -> builder
  }
}

pub fn wb(table: schema.Table) -> WhereBuilder {
  WhereBuilder(table, [])
}

fn build_where(builder: WhereBuilder) -> Result(String, String) {
  let clauses = queue.from_list(builder.clauses)
  let built_clauses_result = build(clauses, [])

  case built_clauses_result {
    Ok(built_clauses) ->
      case list.is_empty(built_clauses) {
        True -> Ok("")
        // No WHERE clause needed
        False -> Ok(" WHERE " <> string.join(built_clauses, " AND "))
      }

    Error(e) -> Error(e)
    // Propagate the error
  }
}

fn build(clauses, acc) -> Result(List(String), String) {
  case queue.pop_back(clauses) {
    Ok(#(Equals(col, val), rest)) ->
      case val {
        ErrorValue(err) -> Error(err)
        // Immediately return the error
        _ -> build(rest, list.append(acc, [col <> " = " <> to_string(val)]))
      }

    Ok(#(Not(eq), rest)) ->
      case build(queue.from_list([eq]), []) {
        Ok(not_clause_list) -> {
          let not_clause =
            "NOT (" <> string.join(not_clause_list, " AND ") <> ")"
          build(rest, list.append(acc, [not_clause]))
        }
        Error(e) -> Error(e)
      }

    Ok(#(Or(eq1, eq2), rest)) ->
      case build(queue.from_list([eq1, eq2]), []) {
        Ok(or_clause_list) -> {
          let or_clause = "(" <> string.join(or_clause_list, " OR ") <> ")"
          build(rest, list.append(acc, [or_clause]))
        }
        Error(e) -> Error(e)
      }

    Ok(#(And(eq1, eq2), rest)) ->
      case build(queue.from_list([eq1, eq2]), []) {
        Ok(and_clause_list) -> {
          let and_clause = "(" <> string.join(and_clause_list, " AND ") <> ")"
          build(rest, list.append(acc, [and_clause]))
        }
        Error(e) -> Error(e)
      }

    _ -> Ok(acc)
  }
}

// Initialize a new query builder for a table
pub fn new(table: schema.Table) -> QueryBuilder {
  QueryBuilder(table, [], [], [], [], [])
}

// Add a select clause (selecting all columns by default)
pub fn select(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    list.map(builder.table.columns, fn(c) { c.name }),
    builder.where_clauses,
    builder.order_by_clauses,
    builder.insert_columns,
    builder.insert_values,
  )
}

// Add a where clause
pub fn where(builder: QueryBuilder, condition: WhereBuilder) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    list.append(builder.where_clauses, condition.clauses),
    // Append Eq directly
    builder.order_by_clauses,
    builder.insert_columns,
    builder.insert_values,
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
    builder.insert_columns,
    builder.insert_values,
  )
}

// Build the final SQL query
pub fn to_sql(builder: QueryBuilder) -> Result(String, String) {
  let base_query =
    "SELECT "
    <> string.join(builder.select_columns, ", ")
    <> " FROM "
    <> builder.table.name

  let where_sql =
    build_where(WhereBuilder(builder.table, builder.where_clauses))

  let order_by_sql = case builder.order_by_clauses {
    [] -> Ok("")
    clauses -> Ok(" ORDER BY " <> string.join(clauses, ", "))
  }

  case where_sql, order_by_sql {
    Ok(where_clause), Ok(order_clause) ->
      Ok(base_query <> where_clause <> order_clause <> ";")
    Error(e), _ -> Error(e)
    // Return error if where_sql is an error
    _, Error(e) -> Error(e)
    // Return error if order_by_sql is an error
  }
}

// Function to add insert columns and values
pub fn insert(
  builder: QueryBuilder,
  // columns: List(String),
  values: List(Value),
) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    builder.where_clauses,
    builder.order_by_clauses,
    list.map(builder.table.columns, fn(c) { c.name }),
    // Set insert columns
    values,
    // Set insert values
  )
}


// Public function to wrap values
pub fn w(v: v) {
  wrap_value(dynamic.from(v))
}

// Build the final SQL insert query
pub fn to_insert_sql(builder: QueryBuilder) -> Result(String, String) {
  case
    list.is_empty(builder.insert_columns),
    list.is_empty(builder.insert_values)
  {
    True, False -> Error("Insert columns and values cannot be empty")
    False, True -> Error("Insert columns and values cannot be empty")
    True, True -> Error("Empty")
    _, _ -> {
      let columns_sql = string.join(builder.insert_columns, ", ")
      let values_sql =
        string.join(list.map(builder.insert_values, to_string), ", ")
      Ok(
        "INSERT INTO "
        <> builder.table.name
        <> " ("
        <> columns_sql
        <> ") VALUES ("
        <> values_sql
        <> ");",
      )
    }
  }
}
