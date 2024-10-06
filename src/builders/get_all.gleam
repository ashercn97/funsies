// DO NOT EDIT: Code generated by matcha from get_all.matcha

import gleam/string_builder.{type StringBuilder}
import gleam/list

import funsies/schema.{type Table, type Column}
import gleam/string fn columns(table: Table) -> StringBuilder {
    let builder = string_builder.from_string("")
    let builder = list.fold(table.columns, builder, fn(builder, col: Column) {
            let builder = string_builder.append(builder, string.replace(string.capitalise(col.name), "_", ""))

        builder
})

    builder
}

fn columns2(table: Table) -> StringBuilder {
    let builder = string_builder.from_string("")
    let builder = list.fold(table.columns, builder, fn(builder, col: Column) {
            let builder = string_builder.append(builder, string.replace(col.name, "_", ""))

        builder
})

    builder
}

pub fn render_builder(table table: Table) -> StringBuilder {
    let builder = string_builder.from_string("")
    let builder = string_builder.append(builder, "
")
    let builder = string_builder.append(builder, "
")
    let builder = string_builder.append(builder, "
")
    let builder = string_builder.append(builder, "
import funs/")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, "_decoder
import funs/")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, "
import gleam/pgo 

pub fn get_all(db: pgo.Connection) -> Result(")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, ".")
    let builder = string_builder.append(builder, string.capitalise(table.name))
    let builder = string_builder.append(builder, "Row, pgo.QueryError) {
  let query = \"SELECT * FROM ")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, "\"
  pgo.execute(db, [], ")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, ".")
    let builder = string_builder.append(builder, table.name)
    let builder = string_builder.append(builder, "_decoder_)
}
")

    builder
}

pub fn render(table table: Table) -> String {
    string_builder.to_string(render_builder(table: table))
}

