//// Schema! This is where the magic happens. Basically, this allows you to define type-safe, code-gen-able schemas
//// that are used to interact with your database.
//// You define them in a src/schema/{name_of_schema}.gleam.
//// Then, define a function called {name_of_schema} and return a table object Created w the DSL
//// 

import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo
import gleam/result
import gleam/string

/// A "column" type. This helps with type safety! V v cool
pub type Column {
  StringColumn(name: String, size: Int)
  IntColumn(name: String)
  BoolColumn(name: String)
  ForeignKeyColumn(
    name: String,
    references_table: String,
    references_column: String,
    references_type: String,
  )
  SerialColumn(name: String)
}

/// A "table" type, with a name and a list of `column` types
/// 
pub type Table {
  Table(name: String, columns: List(Column))
}

/// Create table
/// 
pub fn create_table(name: String) -> Table {
  Table(name, [])
}

/// This gets part of a table and reutnrs a new table
/// 
pub fn get_part_table(table: Table, columns: List(String)) -> Table {
  let filtered_columns =
    columns
    |> list.filter_map(fn(column_name) { check_if_column(table, column_name) })
  Table(table.name, filtered_columns)
}

fn check_if_column(table: Table, column_name: String) -> Result(Column, Nil) {
  table.columns
  |> list.find(fn(column) {
    case column {
      StringColumn(name, _) -> name == column_name
      IntColumn(name) -> name == column_name
      BoolColumn(name) -> name == column_name
      ForeignKeyColumn(name, _, _, _) -> name == column_name
      SerialColumn(name) -> name == column_name
    }
  })
}

/// This adds a string column to the table. 
/// 
pub fn add_string_column(table: Table, name: String, size: Int) -> Table {
  Table(table.name, list.append(table.columns, [StringColumn(name, size)]))
}

/// This adds a int column to the table. 
/// 
pub fn add_int_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [IntColumn(name)]))
}

/// This adds a bool column to the table. 
/// 
pub fn add_bool_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [BoolColumn(name)]))
}

/// This adds a foreign key column to the table. 
/// To use it, pass the name, the referenced table, and the referenced column. And the coolest part? FULL type safety.
pub fn add_foreign_key_column(
  table: Table,
  name: String,
  references_table: Table,
  references_column: String,
) -> Result(Table, String) {
  let maybe_column_referenced =
    list.find(references_table.columns, fn(column) {
      case column {
        StringColumn(ref_name, _) -> ref_name == references_column
        IntColumn(ref_name) -> ref_name == references_column
        BoolColumn(ref_name) -> ref_name == references_column
        SerialColumn(ref_name) -> ref_name == references_column
        ForeignKeyColumn(ref_name, _, _, _) -> ref_name == references_column
      }
    })

  case maybe_column_referenced {
    Ok(referenced_column) -> {
      // Generate the foreign key column based on the type of the referenced column
      let fk_column =
        ForeignKeyColumn(
          name,
          references_table.name,
          references_column,
          sql_type(referenced_column),
          // Get SQL type dynamically
        )
      Ok(Table(table.name, list.append(table.columns, [fk_column])))
    }
    Error(_) ->
      Error(
        "Referenced column "
        <> references_column
        <> " does not exist in table "
        <> references_table.name,
      )
  }
}

/// A serial column. 
/// 
pub fn add_serial_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [SerialColumn(name)]))
}

fn sql_type(column: Column) -> String {
  case column {
    StringColumn(_, size) -> "VARCHAR(" <> int.to_string(size) <> ")"
    IntColumn(_) -> "INT"
    BoolColumn(_) -> "BOOLEAN"
    ForeignKeyColumn(_, _, _, ref_type) -> ref_type
    // Uses the referenced type directly
    SerialColumn(_) -> "SERIAL"
  }
}

/// This generates SQL to ceate the table. Does NOT run it
pub fn generate_create_table_sql(table: Table) -> String {
  let columns_sql =
    table.columns
    |> list.map(fn(column) {
      let column_type = sql_type(column)
      case column {
        StringColumn(name, _) -> name <> " " <> column_type
        IntColumn(name) -> name <> " " <> column_type
        BoolColumn(name) -> name <> " " <> column_type
        ForeignKeyColumn(name, ref_table, ref_column, _) ->
          name
          <> " "
          <> column_type
          <> " REFERENCES "
          <> ref_table
          <> "("
          <> ref_column
          <> ")"
        SerialColumn(name) -> name <> " " <> column_type
      }
    })
    |> string.join(", ")

  "CREATE TABLE " <> table.name <> " (" <> columns_sql <> ");"
}

/// Generates code to drop the table. Pretty simple
pub fn generate_drop_table_sql(table: Table) -> String {
  "DROP TABLE " <> table.name <> ";"
}
