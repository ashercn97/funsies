import db/schema

pub fn users7() {
  schema.create_table("users6")
  |> schema.add_serial_column("id")
  |> schema.add_string_column("name", 255)
  |> schema.add_bool_column("is_active")
}
