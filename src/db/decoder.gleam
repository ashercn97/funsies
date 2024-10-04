import db/schema
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
import gleam/pgo
import gleam/string
import simplifile.{append, read, write}

// Function to append type definitions to an existing file
pub fn generate_row_type(table: schema.Table) {
  let columns = table.columns
  let fields =
    columns
    |> list.map(fn(column) {
      case column {
        schema.StringColumn(name, _) -> name <> ": String"
        schema.IntColumn(name) -> name <> ": Int"
        schema.BoolColumn(name) -> name <> ": Bool"
        schema.SerialColumn(name) -> name <> ": Int"
        _ -> ""
      }
    })
    |> string.join(", ")

  let capitalized_name = string.capitalise(table.name)
  let unique_id = simple_hash(columns)
  let path = "./src/schema/" <> table.name <> ".gleam"
  let type_definition =
    "pub type "
    <> capitalized_name
    <> "Row"
    <> unique_id
    <> " { "
    <> capitalized_name
    <> "Row"
    <> unique_id
    <> "("
    <> fields
    <> ") }\n"

  simplifile.create_directory("./src/schema/")

  // Read the existing file content
  let existing_content = case read(path) {
    Ok(content) -> content
    Error(_) -> ""
  }

  // Check if the type definition already exists
  case string.contains(existing_content, type_definition) {
    True -> io.debug("Type definition already exists, skipping generation.")
    False -> {
      append(to: path, contents: type_definition)
      io.debug("WORKED!")
    }
  }
}

// Function to append decoder functions to an existing file
pub fn generate_decoder_code(table: schema.Table) {
  let columns = table.columns
  let capitalized_name = string.capitalise(table.name)
  let unique_id = simple_hash(columns)
  let decoder_name = table.name <> "_decoder_" <> string.lowercase(unique_id)
  let path = "./src/schema/" <> table.name <> "_decoder.gleam"

  // Read the existing file content
  let existing_content = case read(path) {
    Ok(content) -> content
    Error(_) -> ""
  }

  // Check if the necessary imports are already present
  let import_schema = "import schema/" <> table.name
  let import_decode = "import decode"
  let imports =
    case string.contains(existing_content, import_schema) {
      True -> ""
      False -> import_schema <> "\n"
    }
    <> case string.contains(existing_content, import_decode) {
      True -> ""
      False -> import_decode <> "\n"
    }

  let parameters =
    columns
    |> list.map(fn(column) { "use " <> column.name <> " <- decode.parameter" })
    |> string.join("\n")

  let fields =
    columns
    |> list.index_map(fn(column, index) {
      case column {
        schema.StringColumn(name, _) ->
          "  |> decode.field(" <> int.to_string(index) <> ", decode.string)"
        schema.IntColumn(name) ->
          "  |> decode.field(" <> int.to_string(index) <> ", decode.int)"
        schema.BoolColumn(name) ->
          "  |> decode.field(" <> int.to_string(index) <> ", decode.bool)"
        schema.SerialColumn(name) ->
          "  |> decode.field(" <> int.to_string(index) <> ", decode.int)"
        _ -> "  |> decode.field(" <> int.to_string(index) <> ", decode.string)"
      }
    })
    |> string.join("\n")

  let decoder_code =
    imports
    <> "pub fn "
    <> decoder_name
    <> "() {\n"
    <> "  decode.into({\n"
    <> parameters
    <> "\n    "
    <> table.name
    <> "."
    <> capitalized_name
    <> "Row"
    <> unique_id
    <> "("
    <> columns
    |> list.map(fn(column) { column.name <> ": " <> column.name })
    |> string.join(", ")
    <> ")\n  })\n"
    <> fields
    <> "\n}\n"

  // Check if the decoder function already exists
  case string.contains(existing_content, decoder_code) {
    True -> io.debug("Decoder function already exists, skipping generation.")
    False -> {
      simplifile.create_directory("./src/schema/")
      append(to: path, contents: decoder_code)
      io.debug("WORKED!")
    }
  }
}

fn simple_hash(columns: List(schema.Column)) -> String {
  columns
  |> list.map(fn(column) { string.capitalise(column.name) })
  |> list.map(fn(name) { string.replace(name, "_", "") })
  |> string.join("")
}
