//// A set of utilities to work within a Gleam project. I TOOK MOST OF THIS FROM THE SQUIRREL REPO. TYSM!
////

import filepath
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import globlin
import globlin_fs
import shellout
import simplifile
import tom
import gleam/erlang

/// Returns the project's name, read from the `gleam.toml` file.
///
pub fn name() -> Result(String, Nil) {
  let configuration_path = filepath.join(root(), "gleam.toml")

  use configuration <- try_nil(simplifile.read(configuration_path))
  use toml <- try_nil(tom.parse(configuration))
  use name <- try_nil(tom.get_string(toml, ["name"]))
  Ok(name)
}

fn try_nil(
  result: Result(a, b),
  then do: fn(a) -> Result(c, Nil),
) -> Result(c, Nil) {
  result.try(result.replace_error(result, Nil), do)
}

/// Finds the path of the project's `src` directory.
/// This recursively walks up from the current directory until it finds a
/// `gleam.toml` and builds it from there.
///
pub fn src() -> String {
  filepath.join(root(), "src")
}

/// Finds the path leading to the project's root folder. This recursively walks
/// up from the current directory until it finds a `gleam.toml`.
///
fn root() -> String {
  find_root(".")
}

fn find_root(path: String) -> String {
  let toml = filepath.join(path, "gleam.toml")

  case simplifile.is_file(toml) {
    Ok(False) | Error(_) -> find_root(filepath.join("..", path))
    Ok(True) -> path
  }
}

pub fn find_schema_files() -> Result(dict.Dict(String, String), Nil) {
  let current_root = root()
  io.println("Current root: " <> current_root)
  
  let assert Ok(cwd) = simplifile.current_directory()
  io.debug(simplifile.current_directory())
  
  let assert Ok(pattern) = globlin.new_pattern(filepath.join(cwd, "/src/schema/*.gleam"))
  io.debug(pattern)
  
  case globlin_fs.glob(pattern, returning: globlin_fs.RegularFiles) {
    Ok(files) -> {
      io.println("Files found: " <> files |> string.join(", "))
      
      files
      |> list.map(fn(file) {
        let file_names = file |> filepath.base_name()
        let file_paths = "schema/" <> file_names
        #(file_paths, file |> filepath.base_name() |> filepath.strip_extension())
      })
      |> dict.from_list()
      |> Ok()
    }
    Error(err) -> {
      io.debug(err)
      Error(Nil)
    }
  }
}

pub fn create_files(input: dict.Dict(String, String)) {
  let values = dict.values(input)
  simplifile.create_directory(src() <> "/funs/")
  let code =
    "// code to be run to generate the types and decoders"
    <> "\n// DO NOT MODIFY"
    <> "\n // generated by `funsies`"
    <> "\n\nimport db/decoder"
    <> "\n\n"
    <> string.concat(
      list.map(values, fn(val) { "import schema/" <> val <> "\n" }),
    )
    <> "\n"
    <> "\n"
    <> "pub fn main() {"
    <> string.concat(
      list.map(values, fn(val) {
        "decoder.generate_row_type("
        <> val
        <> "."
        <> val
        <> "()"
        <> ")"
        <> "\n"
        <> "decoder.generate_decoder_code("
        <> val
        <> "."
        <> val
        <> "()"
        <> ")"
        <> "\n"
      }),
    )
    <> "}"

  simplifile.write(src() <> "/funs/generate.gleam", code)
}

pub fn work() {
    let assert Ok(cwd) = simplifile.current_directory()
    io.debug(cwd)
  case
    shellout.command(
      "gleam",
      ["run", "-m", "funs/generate"],
      in: "./",
      opt: [],
    )
  {
    Ok(res) -> {
      io.println("Successfully generated types and decoders.")
      io.debug(res)
      Ok(Nil)
    }
    Error(e) -> {
      io.debug("Error generating types and decoders")
      io.debug(e)
      Error(Nil)
    }
  }
}
