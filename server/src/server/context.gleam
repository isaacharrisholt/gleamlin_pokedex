import decode/zero
import gleam/dynamic
import gleam/json
import gleam/option.{type Option}
import pevensie/auth.{type PevensieAuth, type Session, type User}
import pevensie/drivers.{type Connected}
import pevensie/drivers/postgres.{type Postgres, type PostgresError}
import pog

pub type UserMetadata {
  UserMetadata(name: String)
}

pub fn user_metadata_decoder(
  data: dynamic.Dynamic,
) -> Result(UserMetadata, dynamic.DecodeErrors) {
  let decoder = {
    use name <- zero.field("name", zero.string)
    zero.success(UserMetadata(name:))
  }

  zero.run(data, decoder)
}

pub fn user_metadata_encoder(data: UserMetadata) -> json.Json {
  json.object([#("name", json.string(data.name))])
}

pub type Context {
  Context(
    user: Option(UserWithSession),
    auth: PevensieAuth(Postgres, PostgresError, UserMetadata, Connected),
    db: pog.Connection,
  )
}

pub type UserWithSession {
  UserWithSession(user: User(UserMetadata), session: Session)
}
