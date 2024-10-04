import cli/project
import gleam/dict
import gleam/erlang/process
import gleam/string
import gleam/io

pub fn main() {
  let assert Ok(output) = project.find_schema_files()
  io.println("Schema files to process: " <> dict.keys(output) |> string.join(", "))
  
  project.create_files(output)
  process.sleep(5)
  project.work()
}
