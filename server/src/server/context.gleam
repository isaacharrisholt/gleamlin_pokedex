import gleam/option.{type Option}
import pevensie/auth.{type PevensieAuth, type Session, type User}
import pevensie/cache.{type PevensieCache}
import pevensie/drivers.{type Connected}
import pevensie/postgres.{type Postgres, type PostgresError}
import pog
import server/user.{type UserMetadata, UserMetadata}

pub type Context {
  Context(
    user: Option(UserWithSession),
    auth: PevensieAuth(Postgres, PostgresError, UserMetadata, Connected),
    db: pog.Connection,
    cache: PevensieCache(Postgres, PostgresError, Connected),
  )
}

pub type UserWithSession {
  UserWithSession(user: User(UserMetadata), session: Session)
}
