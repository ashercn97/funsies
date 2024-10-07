import cli_project/project
import gleam/dict
import gleam/erlang/process
import gleam/io
import gleam/string
import gleam_community/ansi

pub fn main() {
  let assert Ok(output) = project.find_schema_files()

  io.println(
    ansi.bold(ansi.underline(ansi.green("Starting schema file processing..."))),
  )
  io.println(ansi.strikethrough("                           "))

  io.println(ansi.bold(ansi.magenta("Found schema files to process!")))
  io.debug(dict.keys(output) |> string.join(", "))
  io.println(ansi.strikethrough("                           "))

  io.println(ansi.bold(ansi.cyan("Creating the `generate` file...")))
  project.create_files(output)
  process.sleep(5)
  io.println(ansi.strikethrough("                           "))

  io.println(
    ansi.bold(ansi.yellow("Generating the types + decoders + insert code...")),
  )
  project.work()
  io.println(ansi.strikethrough("                           "))

  io.println(ansi.bold(ansi.underline(ansi.green("Processing complete!"))))
}
