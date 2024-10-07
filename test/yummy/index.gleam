import funsies/query/yummy as y
import funsies/schema
import utils/utils.{run}

pub fn table() {
  schema.create_table("tests")
  |> schema.add_serial_column("id")
  |> schema.add_string_column("name", 255)
  |> schema.add_bool_column("worked")
}

pub fn one_test() {
  let table = table()

  let truth = "SELECT id, name, worked FROM tests;"
  let output =
    y.new(table)
    |> y.select()
    |> y.to_sql

  run(output, truth)
}

pub fn two_test() {
  let table = table()
  let truth = "SELECT id, name, worked FROM tests WHERE id = 1;"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", 1),
    )
    |> y.to_sql

  run(output, truth)
}

pub fn three_test() {
  let table = table()
  let truth = "SELECT id, name, worked FROM tests WHERE NOT (id = 1);"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", 1)
      |> y.not(),
    )
    |> y.to_sql
  run(output, truth)
}

pub fn four_test() {
  let table = table()
  let truth =
    "SELECT id, name, worked FROM tests WHERE (NOT (name = 'hi') AND id = 1);"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("name", "hi")
      |> y.not()
      |> y.equals("id", 1)
      |> y.and(),
    )
    |> y.to_sql

  run(output, truth)
}

pub fn five_test() {
  let table = table()
  let truth =
    "SELECT id, name, worked FROM tests WHERE (id = 1 OR name = 'test');"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", 1)
      |> y.equals("name", "test")
      |> y.or(),
    )
    |> y.to_sql

  run(output, truth)
}

pub fn six_test() {
  let table = table()
  let truth =
    "SELECT id, name, worked FROM tests WHERE (id = 1 AND worked = TRUE);"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", 1)
      |> y.equals("worked", True)
      |> y.and(),
    )
    |> y.to_sql

  run(output, truth)
}

pub fn seven_test() {
  let table = table()
  let truth =
    "SELECT id, name, worked FROM tests WHERE (NOT (id = 1) OR worked = FALSE);"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("id", 1)
      |> y.not()
      |> y.equals("worked", False)
      |> y.or(),
    )
    |> y.to_sql

  run(output, truth)
}

pub fn eight_test() {
  let table = table()
  let truth =
    "SELECT id, name, worked FROM tests WHERE (name = 'test' AND (id = 1 OR worked = TRUE));"
  let output =
    y.new(table)
    |> y.select()
    |> y.where(
      y.wb(table)
      |> y.equals("name", "test")
      |> y.equals("id", 1)
      |> y.equals("worked", True)
      |> y.or()
      |> y.and(),
    )
    |> y.to_sql

  run(output, truth)
}
