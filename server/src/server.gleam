import gleam/erlang/process
import gleam/io
import gleam/option.{None, Some}
import gleam/string_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import mist
import pevensie/auth
import pevensie/drivers/postgres
import server/account
import server/auth as server_auth
import server/context.{type Context, Context}
import server/scaffold.{page_scaffold}
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub fn main() {
  let cfg =
    postgres.PostgresConfig(
      ..postgres.default_config(),
      host: "localhost",
      port: 5432,
      database: "postgres",
      user: "postgres",
    )
  let auth_driver = postgres.new_auth_driver(cfg)
  let secret_key_base = wisp.random_string(64)
  let pevensie_cookie_key = "my-super-secret-cookie-string"

  let pevensie_auth =
    auth.new(
      cookie_key: pevensie_cookie_key,
      driver: auth_driver,
      user_metadata_decoder: context.user_metadata_decoder,
      user_metadata_encoder: context.user_metadata_encoder,
    )
  let assert Ok(pevensie_auth) =
    pevensie_auth
    |> auth.connect

  let ctx = Context(None, pevensie_auth)

  wisp.configure_logger()
  let assert Ok(_) =
    wisp_mist.handler(handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  io.println("Serving on http://localhost:8000")
  process.sleep_forever()
}

fn handle_request(req: Request, ctx: Context) -> Response {
  use ctx <- server_auth.auth_middleware(req, ctx)
  case wisp.path_segments(req) |> io.debug {
    [] -> home(req, ctx)
    ["account", ..path] -> account.account_handler(req, path, ctx)
    ["login"] -> login(req, ctx)
    ["signup"] -> signup(req, ctx)
    ["auth", ..path] -> server_auth.auth_handler(req, path, ctx)
    _ -> wisp.not_found()
  }
}

fn home(req: Request, ctx: Context) -> Response {
  use ctx <- server_auth.auth_middleware(req, ctx)
  let view =
    page_scaffold(
      html.div([], [
        html.h1([], [html.text("Pokedex")]),
        ..case ctx.user {
          Some(context.UserWithSession(user:, ..)) -> [
            html.p([], [html.text("Logged in as " <> user.email)]),
          ]
          None -> []
        }
      ]),
    )

  wisp.html_response(
    element.to_document_string(view) |> string_tree.from_string,
    200,
  )
}

fn login(_req: Request, ctx: Context) -> Response {
  case ctx.user {
    Some(_) -> wisp.redirect("/account")
    None -> {
      let view =
        page_scaffold(
          html.div([], [
            html.h1([], [html.text("Log in")]),
            html.form(
              [attribute.method("post"), attribute.action("/auth/login")],
              [
                html.input([
                  attribute.name("email"),
                  attribute.type_("email"),
                  attribute.placeholder("Email"),
                ]),
                html.input([
                  attribute.name("password"),
                  attribute.type_("password"),
                  attribute.placeholder("Password"),
                ]),
                html.button([attribute.type_("submit")], [html.text("Log in")]),
              ],
            ),
          ]),
        )

      wisp.html_response(
        element.to_document_string(view) |> string_tree.from_string,
        200,
      )
    }
  }
}

fn signup(_req: Request, ctx: Context) -> Response {
  case ctx.user {
    Some(_) -> wisp.redirect("/account")
    None -> {
      let view =
        page_scaffold(
          html.div([], [
            html.h1([], [html.text("Sign up")]),
            html.form(
              [attribute.method("post"), attribute.action("/auth/user")],
              [
                html.input([
                  attribute.name("email"),
                  attribute.type_("email"),
                  attribute.placeholder("Email"),
                ]),
                html.input([
                  attribute.name("password"),
                  attribute.type_("password"),
                  attribute.placeholder("Password"),
                ]),
                html.input([
                  attribute.name("password_confirmation"),
                  attribute.type_("password"),
                  attribute.placeholder("Password confirmation"),
                ]),
                html.button([attribute.type_("submit")], [html.text("Sign up")]),
              ],
            ),
          ]),
        )

      wisp.html_response(
        element.to_document_string(view) |> string_tree.from_string,
        200,
      )
    }
  }
}
