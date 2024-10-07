import gleeunit/should

pub fn fail() {
  should.be_false(True)
}

pub fn run(output, truth) {
  case output {
    Ok(t) -> should.equal(t, truth)
    Error(_) -> fail()
  }
}
