import funsies/query/yummy as y
import funsies/schema
import gleeunit/should

pub fn table() {
  schema.create_table("tests")
  |> schema.add_serial_column("id")
  |> schema.add_string_column("name", 255)
  |> schema.add_bool_column("worked")
}

pub fn one_typesafe_gleam_test() {
  // setting bool to int
  let table = table()
  let value = True
  let query =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", value),
    )
    |> y.to_sql
  should.be_error(query)
}

pub fn two_typesafe_gleam_test() {
  // setting bool to string
  let table = table()
  let value = True
  let query =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("name", value),
    )
    |> y.to_sql
  should.be_error(query)
}

pub fn three_typesafe_gleam_test() {
  // setting Int to String
  let table = table()
  let value = 2
  let query =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("name", value),
    )
    |> y.to_sql

  should.be_error(query)
}

