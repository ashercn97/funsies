import db/schema

pub fn users6() {
  schema.create_table("users7")
  |> schema.add_serial_column("id")
  |> schema.add_string_column("name", 255)
  |> schema.add_bool_column("is_active")
}
