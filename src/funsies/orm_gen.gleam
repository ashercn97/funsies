/// This uses the matcha templates from `builder` to generate files. Only one currently used is create_insert, which creates the type-safe insert func.
/// 
import funsies/builders/by_id
import funsies/builders/get_all
import funsies/builders/insert
import funsies/schema
import simplifile

pub fn create_by_id(path: String, table: schema.Table) {
  let str = by_id.render(table)
  let assert Ok(results) = simplifile.write(path, contents: str)
}

pub fn create_get_all(path: String, table: schema.Table) {
  let str = get_all.render(table)
  let assert Ok(results) = simplifile.write(path, contents: str)
}

/// uses the insert template to create a type-safe insert function!
pub fn create_insert(path: String, table: schema.Table) {
  let str = insert.render(table)
  let results = simplifile.write(path, contents: str)
  results
}
