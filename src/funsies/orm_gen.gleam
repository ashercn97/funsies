import funsies/schema
import simplifile
import builders/by_id
import builders/get_all
import builders/insert

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
  let results = simplifile.write(path, contents: str)
  results
}
