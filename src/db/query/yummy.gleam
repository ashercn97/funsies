import db/schema
import gleam/bool
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/queue
import gleam/result
import gleam/string

pub type QueryBuilder {
  QueryBuilder(
    table: schema.Table,
    select_columns: List(String),
    where_clauses: List(String),
    order_by_clauses: List(String),
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

pub fn equals(builder: WhereBuilder, col: String, value: v) {
  WhereBuilder(
    builder.table,
    list.append(builder.clauses, [Equals(col, wrap_value(dynamic.from(value)))]),
  )
}

pub fn not(builder: WhereBuilder) -> WhereBuilder {
  case queue.pop_back(queue.from_list(builder.clauses)) {
    Ok(#(eq, rest)) ->
      WhereBuilder(
        builder.table,
        list.append(queue.to_list(rest), [Not(eq)])
      )
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
            list.append(queue.to_list(rest2), [Or(eq1, eq2)])
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
            list.append(queue.to_list(rest2), [And(eq1, eq2)])
          )
        _ -> builder
      }
    _ -> builder
  }
}

pub fn wb(table: schema.Table) -> WhereBuilder {
  WhereBuilder(table, [])
}

fn build_where(builder: WhereBuilder) -> String {
  let clauses = queue.from_list(builder.clauses)

  string.join(build(clauses, []), " AND ")
}

fn build(clauses, acc) {
  case queue.pop_back(clauses) {
    Ok(#(Equals(col, val), rest)) ->
      build(rest, list.append(acc, [col <> " = " <> to_string(val)]))
    Ok(#(Not(eq), rest)) -> {
      let not_clause = "NOT (" <> string.join(build(queue.from_list([eq]), []), " AND ") <> ")"
      build(rest, list.append(acc, [not_clause]))
    }
    Ok(#(Or(eq1, eq2), rest)) -> {
      let or_clause =
        "("
        <> string.join(build(queue.from_list([eq1]), []), " AND ")
        <> " OR "
        <> string.join(build(queue.from_list([eq2]), []), " AND ")
        <> ")"
      build(rest, list.append(acc, [or_clause]))
    }
    Ok(#(And(eq1, eq2), rest)) -> {
      let and_clause =
        "("
        <> string.join(build(queue.from_list([eq1]), []), " AND ")
        <> " AND "
        <> string.join(build(queue.from_list([eq2]), []), " AND ")
        <> ")"
      build(rest, list.append(acc, [and_clause]))
    }
    _ -> acc
  }
}

// Initialize a new query builder for a table
pub fn new(table: schema.Table) -> QueryBuilder {
  QueryBuilder(table, [], [], [])
}

// Add a select clause (selecting all columns by default)
pub fn select(builder: QueryBuilder) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    list.map(builder.table.columns, fn(c) { c.name }),
    builder.where_clauses,
    builder.order_by_clauses,
  )
}

// Add a where clause
pub fn where(builder: QueryBuilder, condition: WhereBuilder) -> QueryBuilder {
  QueryBuilder(
    builder.table,
    builder.select_columns,
    list.append(builder.where_clauses, [build_where(condition)]),
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
