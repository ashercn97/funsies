//// A super small module. This just makes it easier to run the queries from `yummy`
//// 

import gleam/pgo

/// The only function. Runs the query, given a sql query, a db connection, and a decoder
/// 
pub fn run(sql: String, db: pgo.Connection, decoder) {
  sql
  |> pgo.execute(db, [], decoder)
}
