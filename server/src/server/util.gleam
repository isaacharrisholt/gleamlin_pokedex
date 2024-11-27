import gleam/io
import gleam/option.{type Option, None, Some}
import wisp

pub fn result_to_option(result: Result(a, b)) -> Option(a) {
  case result {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

pub fn wisp_try(
  result: Result(a, b),
  next: fn(a) -> wisp.Response,
) -> wisp.Response {
  case result {
    Ok(a) -> next(a)
    Error(_) -> {
      io.println("error encountered")
      let _ = io.debug(result)
      wisp.internal_server_error()
    }
  }
}
