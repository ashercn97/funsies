import db/decoder
import db/schema
import decode
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/pgo
import gleam/result
import gleam/string

pub type Entity =
  pgo.Returned(Dynamic)

pub fn blank() {
  let hi = 1
  case hi {
    1 -> Ok(pgo.Returned(0, []))
    _ -> Error(pgo.PostgresqlError("1", "2", "3"))
  }
}

pub type Getter(row) =
  fn(Int) -> Result(pgo.Returned(row), pgo.QueryError)

pub type GetterAll(row) =
  fn() -> Result(pgo.Returned(row), pgo.QueryError)

pub type Setter(row) =
  fn(List(pgo.Value)) -> Result(pgo.Returned(row), pgo.QueryError)

pub type SetterUpdate(row) =
  fn(Int, List(pgo.Value)) -> Result(pgo.Returned(row), pgo.QueryError)

pub type SetterDelete(row) =
  fn(Int) -> Result(pgo.Returned(row), pgo.QueryError)

pub type ORM(row) {
  ORM(
    by_id: Getter(row),
    get_all: GetterAll(row),
    insert: Setter(row),
    update: SetterUpdate(row),
    delete: SetterDelete(row),
    decoder: decode.Decoder(row),
  )
}

pub fn make_by_id(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> Getter(row) {
  let query = "SELECT * FROM " <> table.name <> " WHERE id=$1"
  fn(id) {
    query
    |> pgo.execute(db, [pgo.int(id)], decoder.continuation)
  }
}

pub fn make_get_all(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> GetterAll(row) {
  let query = "SELECT * FROM " <> table.name
  fn() {
    query
    |> pgo.execute(db, [], decoder.continuation)
  }
}

pub fn generate_insert_sql(table: schema.Table) -> String {
  let columns =
    table.columns
    |> list.filter(fn(column) {
      case column {
        schema.SerialColumn(_) -> False
        _ -> True
      }
    })
    |> list.map(fn(column) { column.name })
    |> string.join(", ")

  let values =
    table.columns
    |> list.filter(fn(column) {
      case column {
        schema.SerialColumn(_) -> False
        _ -> True
      }
    })
    |> list.index_map(fn(_, i) { "$" <> int.to_string(i + 1) })
    |> string.join(", ")

  "INSERT INTO "
  <> table.name
  <> " ("
  <> columns
  <> ") VALUES ("
  <> values
  <> ")"
}

pub fn generate_update_sql(table: schema.Table) -> String {
  let column_assignments =
    table.columns
    |> list.index_map(fn(column, i) {
      column.name <> " = $" <> int.to_string(i + 1)
    })
    |> string.join(", ")

  "UPDATE "
  <> table.name
  <> " SET "
  <> column_assignments
  <> " WHERE id = $"
  <> int.to_string(list.length(table.columns) + 1)
}

pub fn generate_delete_sql(table: schema.Table) -> String {
  "DELETE FROM " <> table.name <> " WHERE id = $1"
}

pub fn make_insert(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> Setter(row) {
  let sql = generate_insert_sql(table)
  fn(values: List(pgo.Value)) {
    sql |> pgo.execute(db, values, decoder.continuation)
  }
}

pub fn make_update(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> SetterUpdate(row) {
  let sql = generate_update_sql(table)
  fn(id: Int, values: List(pgo.Value)) {
    sql
    |> pgo.execute(db, list.append([pgo.int(id)], values), decoder.continuation)
  }
}

pub fn make_delete(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> SetterDelete(row) {
  let sql = generate_delete_sql(table)
  fn(id: Int) { sql |> pgo.execute(db, [pgo.int(id)], decoder.continuation) }
}

pub fn orm(
  row,
  table: schema.Table,
  db: pgo.Connection,
  decoder: decode.Decoder(row),
) -> ORM(row) {
  ORM(
    by_id: make_by_id(row, table, db, decoder),
    get_all: make_get_all(row, table, db, decoder),
    insert: make_insert(row, table, db, decoder),
    update: make_update(row, table, db, decoder),
    delete: make_delete(row, table, db, decoder),
    decoder: decoder,
  )
}
