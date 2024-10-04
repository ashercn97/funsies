import db/decoder
import db/orm
import db/query/yum
import db/schema
import gleam/dynamic
import gleam/io
import gleam/option
import gleam/pgo
import schema/users6
import schema/users6_decoder

pub fn main() {
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        database: "database_yay",
        user: "postgres",
        port: 5432,
        password: option.Some("postgres"),
        pool_size: 15,
      ),
    )

  let user_table =
    schema.create_table("users6")
    |> schema.add_serial_column("id")
    |> schema.add_string_column("name", 255)
    |> schema.add_bool_column("is_active")


  let part_table = schema.get_part_table(user_table, ["id", "name"])

  pgo.execute(
    schema.generate_create_table_sql(user_table),
    db,
    [],
    dynamic.dynamic,
  )

  let user_decoder = users6_decoder.users6_decoder_idnameisactive()

  let user_orm =
    orm.orm(users6.Users6RowIdNameIsactive, user_table, db, user_decoder)

  let fetched_user_result = user_orm.by_id(2)

  io.debug(fetched_user_result)

  let all_users_result = user_orm.get_all()

  io.debug(all_users_result)

  let new_user_values = [pgo.text("Alice"), pgo.bool(True)]

  let insert_result = user_orm.insert(new_user_values)

  io.debug(insert_result)

  let query =
    yum.new("users6")
    |> yum.select(["name", "is_active"])
    |> yum.where("is_active = TRUE")
    |> yum.where("name != Alice")
    |> yum.order_by("name", "ASC")
    |> yum.to_sql()

  io.debug(query)
}
