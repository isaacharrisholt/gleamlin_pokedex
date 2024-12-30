import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/list
import gleam/result
import server/util

pub type UserMetadata {
  UserMetadata(
    name: String,
    bio: String,
    number: Int,
    types: UserTypes,
    moves: List(Move),
    ability: Ability,
    avatar_url: String,
  )
}

pub fn user_metadata_decoder() -> Decoder(UserMetadata) {
  use name <- decode.field("name", decode.string)
  use bio <- decode.field("bio", decode.string)
  use number <- decode.field("number", decode.int)
  use types <- decode.field("types", user_types_decoder())
  use moves <- decode.field("moves", decode.list(move_decoder()))
  use ability <- decode.field("ability", ability_decoder())
  use avatar_url <- decode.field("avatar_url", decode.string)
  decode.success(UserMetadata(
    name:,
    bio:,
    number:,
    types:,
    moves:,
    ability:,
    avatar_url:,
  ))
}

pub fn user_metadata_encoder(data: UserMetadata) -> json.Json {
  json.object([
    #("name", json.string(data.name)),
    #("bio", json.string(data.bio)),
    #("number", json.int(data.number)),
    #("types", user_types_encoder(data.types)),
    #("moves", json.array(data.moves, move_encoder)),
    #("ability", ability_encoder(data.ability)),
    #("avatar_url", json.string("avatar_url")),
  ])
}

pub fn default_user_metadata(name: String) -> UserMetadata {
  let type_ = get_random_type_for_user(name)
  UserMetadata(
    name:,
    bio: "A friendly Gleamlin!",
    number: 0,
    types: SingleType(type_),
    moves: [],
    ability: Ability(
      name: "Gleaming",
      description: "Powers up " <> type_.name <> "-type moves when threatened.",
    ),
    // TODO: fun default
    avatar_url: "TODO",
  )
}

pub type UserTypes {
  SingleType(Type)
  DualTypes(Type, Type)
}

fn user_types_decoder() -> decode.Decoder(UserTypes) {
  decode.list(of: type_decoder())
  |> decode.then(fn(types) {
    case types {
      [primary] -> decode.success(SingleType(primary))
      [primary, secondary] -> decode.success(DualTypes(primary, secondary))
      [] -> decode.failure(SingleType(Type(name: "", colour: "")), "UserTypes")
      _ -> decode.failure(SingleType(Type(name: "", colour: "")), "UserTypes")
    }
  })
}

fn user_types_encoder(data: UserTypes) -> json.Json {
  json.array(
    case data {
      SingleType(primary) -> [primary]
      DualTypes(primary, secondary) -> [primary, secondary]
    },
    type_encoder,
  )
}

pub type Type {
  // TODO: use a colour package
  Type(name: String, colour: String)
}

fn type_decoder() -> decode.Decoder(Type) {
  use name <- decode.field("name", decode.string)
  use colour <- decode.field("colour", decode.string)
  decode.success(Type(name:, colour:))
}

fn type_encoder(data: Type) -> json.Json {
  json.object([
    #("name", json.string(data.name)),
    #("colour", json.string(data.colour)),
  ])
}

pub fn default_types() -> List(Type) {
  // TODO
  [Type(name: "Grass", colour: "green")]
}

fn get_random_type_for_user(name: String) -> Type {
  let types = default_types()
  let max = list.length(types)

  let idx = util.hash_string_to_int(name, min: 0, max:) |> result.unwrap(0)

  let assert Ok(type_) = util.list_at(types, idx)
  type_
}

pub type Move {
  Move(
    name: String,
    description: String,
    type_: Type,
    power: Int,
    accuracy: Int,
  )
}

fn move_decoder() -> Decoder(Move) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use type_ <- decode.field("type", type_decoder())
  use power <- decode.field("power", decode.int)
  use accuracy <- decode.field("accuracy", decode.int)

  decode.success(Move(name:, description:, type_:, power:, accuracy:))
}

fn move_encoder(data: Move) -> json.Json {
  json.object([
    #("name", json.string(data.name)),
    #("description", json.string(data.description)),
    #("type", type_encoder(data.type_)),
    #("power", json.int(data.power)),
    #("accuracy", json.int(data.accuracy)),
  ])
}

pub type Ability {
  Ability(name: String, description: String)
}

fn ability_decoder() -> Decoder(Ability) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)

  decode.success(Ability(name:, description:))
}

fn ability_encoder(data: Ability) -> json.Json {
  json.object([
    #("name", json.string(data.name)),
    #("description", json.string(data.description)),
  ])
}
