import gleam/dynamic
import gleam/json
import gleam/option.{type Option}
import pevensie/auth.{type PevensieAuth, type Session, type User}
import pevensie/drivers.{type Connected}
import pevensie/drivers/postgres.{type Postgres, type PostgresError}

pub type UserMetadata {
  UserMetadata
}

pub fn user_metadata_decoder(
  _data: dynamic.Dynamic,
) -> Result(UserMetadata, dynamic.DecodeErrors) {
  Ok(UserMetadata)
}

pub fn user_metadata_encoder(_data: UserMetadata) -> json.Json {
  json.object([])
}

pub type Context {
  Context(
    user: Option(UserWithSession),
    auth: PevensieAuth(Postgres, PostgresError, UserMetadata, Connected),
  )
}

pub type UserWithSession {
  UserWithSession(user: User(UserMetadata), session: Session)
}
