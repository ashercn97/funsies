import gleam/pgo

pub fn run(sql: String, db: pgo.Connection, decoder) {
  sql
  |> pgo.execute(db, [], decoder)
}
