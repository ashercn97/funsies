import db/schema
import simplifile
import templates/by_id
import templates/get_all
import templates/insert

pub fn create_by_id(path: String, table: schema.Table) {
  let str = by_id.render(table)
  let assert Ok(results) = simplifile.write(path, contents: str)
}

pub fn create_get_all(path: String, table: schema.Table) {
  let str = get_all.render(table)
  let assert Ok(results) = simplifile.write(path, contents: str)
}

pub fn create_insert(path: String, table: schema.Table) {
  let str = insert.render(table)
  let assert Ok(results) = simplifile.write(path, contents: str)
}
