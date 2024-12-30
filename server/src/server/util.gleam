import gleam/bit_array
import gleam/int
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

pub fn list_at(list: List(a), idx: Int) -> Result(a, Nil) {
  case list {
    [] -> Error(Nil)
    [head, ..] if idx == 0 -> Ok(head)
    [_, ..tail] if idx > 0 -> list_at(tail, idx - 1)
    _ -> Error(Nil)
  }
}

fn do_sum_bit_array(ba: BitArray, acc: Int) -> Int {
  case ba {
    <<u8:size(8)-unsigned, rest:bits>> -> do_sum_bit_array(rest, acc + u8)
    _ -> acc
  }
}

// Leniently sum a bit array, discarding any remaining bits if the bit array
// does not contain an exact number of u8 bytes.
fn sum_bit_array(ba: BitArray) -> Int {
  do_sum_bit_array(ba, 0)
}

pub fn hash_string_to_int(
  str: String,
  min min: Int,
  max max: Int,
) -> Result(Int, Nil) {
  bit_array.from_string(str)
  |> sum_bit_array
  |> fn(num) {
    case int.modulo(num, max) {
      Ok(rem) -> Ok(rem + min)
      Error(_) -> Error(Nil)
    }
  }
}
