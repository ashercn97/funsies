import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, Some}
import gleam/pgo
import gleam/result
import gleam/string

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

pub type Table {
  Table(name: String, columns: List(Column))
}

pub fn create_table(name: String) -> Table {
  Table(name, [])
}

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

pub fn add_string_column(table: Table, name: String, size: Int) -> Table {
  Table(table.name, list.append(table.columns, [StringColumn(name, size)]))
}

pub fn add_int_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [IntColumn(name)]))
}

pub fn add_bool_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [BoolColumn(name)]))
}

pub fn add_foreign_key_column(
  table: Table,
  name: String,
  references_table: Table,
  references_column: String,
) -> Table {
  let column_referenced = case
    list.find(references_table.columns, one_that: fn(a) {
      a.name == references_column
    })
  {
    Ok(c) -> c
    Error(_) -> {
      let assert Ok(value) = list.first(references_table.columns)
      value
    }
  }
  Table(
    table.name,
    list.append(table.columns, [
      ForeignKeyColumn(
        name,
        references_table.name,
        references_column,
        string.capitalise(sql_type(column_referenced)),
      ),
    ]),
  )
}

pub fn add_serial_column(table: Table, name: String) -> Table {
  Table(table.name, list.append(table.columns, [SerialColumn(name)]))
}

fn sql_type(column: Column) -> String {
  case column {
    StringColumn(_, size) -> "VARCHAR(" <> int.to_string(size) <> ")"
    IntColumn(_) -> "INT"
    BoolColumn(_) -> "BOOLEAN"
    ForeignKeyColumn(_, _, _, _) -> "INT"
    // Assuming foreign keys are INT
    SerialColumn(_) -> "SERIAL"
  }
}

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

pub fn generate_drop_table_sql(table: Table) -> String {
  "DROP TABLE " <> table.name <> ";"
}
