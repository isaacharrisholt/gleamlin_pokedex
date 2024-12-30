import formz
import formz/field
import formz_lustre/definitions
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import pevensie/auth
import server/context.{type Context, Context}
import server/user
import server/util
import wisp.{type Request, type Response}

pub const session_cookie_name = "gleamlin-pokedex-session"

pub fn auth_handler(req: Request, path: List(String), ctx: Context) -> Response {
  case path, req.method {
    ["user"], Post -> handle_create_user(req, ctx)
    ["login"], Post -> handle_login(req, ctx)
    ["logout"], Post | ["logout"], Get -> handle_logout(req, ctx)
    _, _ -> wisp.not_found()
  }
}

pub fn auth_middleware(
  req: Request,
  ctx: Context,
  next: fn(Context) -> Response,
) -> Response {
  let user_agent =
    request.get_header(req, "user-agent") |> util.result_to_option

  let user_with_session = case
    wisp.get_cookie(req, session_cookie_name, wisp.PlainText)
  {
    Error(_) -> None
    Ok(cookie) -> {
      io.println("cookie: " <> cookie)
      case auth.validate_session_cookie(ctx.auth, cookie) {
        Error(_) -> None
        Ok(session_id) -> {
          io.println("valid cookie, session id: " <> session_id)
          case auth.get_session(ctx.auth, session_id:, user_agent:, ip: None) {
            Error(_) -> None
            Ok(session) -> {
              io.println("got session for user: " <> session.user_id)
              let assert Ok(user) =
                auth.get_user_by_id(ctx.auth, session.user_id)
              Some(context.UserWithSession(user:, session:))
            }
          }
        }
      }
    }
  }

  let ctx = case user_with_session {
    None -> ctx
    _ -> Context(..ctx, user: user_with_session)
  }

  next(ctx)
}

pub fn auth_guard(
  ctx: Context,
  next: fn(context.UserWithSession) -> Response,
) -> Response {
  case ctx.user {
    Some(user) -> next(user)
    None -> wisp.redirect("/login")
  }
}

pub fn signup_form() {
  use email <- formz.require(
    field.field("email") |> field.set_label("Email"),
    definitions.email_field(),
  )
  use password <- formz.require(
    field.field("password") |> field.set_label("Password"),
    definitions.password_field(),
  )
  use password_confirmation <- formz.require(
    field.field("password_confirmation")
      |> field.set_label("Password confirmation"),
    definitions.password_field(),
  )

  formz.create_form(#(email, password, password_confirmation))
}

fn handle_create_user(req: Request, ctx: Context) -> Response {
  use form <- wisp.require_form(req)

  let form_result =
    signup_form()
    |> formz.data(form.values)
    |> formz.parse

  case form_result {
    Ok(#(email, pass, pass_conf)) if pass == pass_conf -> {
      let assert Ok(name) = string.split(email, "@") |> list.first
      let user_result =
        auth.create_user_with_email(
          ctx.auth,
          email,
          pass,
          user.default_user_metadata(name),
        )

      case user_result {
        // TODO: handle error cases better
        Error(_) -> wisp.internal_server_error()
        Ok(_) -> {
          let user_agent =
            request.get_header(req, "user-agent") |> util.result_to_option
          let login_result =
            auth.log_in_user(
              ctx.auth,
              email:,
              password: pass,
              user_agent: user_agent,
              ip: None,
            )

          case login_result {
            Error(_) -> wisp.internal_server_error()
            Ok(#(session, _)) -> {
              let assert Ok(cookie) =
                auth.create_session_cookie(ctx.auth, session)
              wisp.redirect("/account")
              |> wisp.set_cookie(
                request: req,
                name: session_cookie_name,
                value: cookie,
                max_age: 60 * 60 * 23,
                security: wisp.PlainText,
              )
            }
          }
        }
      }
    }
    _ -> wisp.bad_request()
  }
}

pub fn login_form() {
  use email <- formz.require(
    field.field("email") |> field.set_label("Email"),
    definitions.email_field(),
  )
  use password <- formz.require(
    field.field("password") |> field.set_label("Password"),
    definitions.password_field(),
  )

  formz.create_form(#(email, password))
}

fn handle_login(req: Request, ctx: Context) -> Response {
  case ctx.user {
    Some(_) -> wisp.redirect("/account")
    None -> {
      use form <- wisp.require_form(req)

      let form_result =
        login_form()
        |> formz.data(form.values)
        |> formz.parse

      case form_result {
        Ok(#(email, pass)) -> {
          let user_agent =
            request.get_header(req, "user-agent") |> util.result_to_option
          let login_result =
            auth.log_in_user(
              ctx.auth,
              email:,
              password: pass,
              user_agent:,
              ip: None,
            )
          case login_result {
            Error(_) -> wisp.bad_request()
            Ok(#(session, _)) -> {
              let assert Ok(cookie) =
                auth.create_session_cookie(ctx.auth, session)
              wisp.redirect("/account")
              |> wisp.set_cookie(
                request: req,
                name: session_cookie_name,
                value: cookie,
                max_age: 60 * 60 * 23,
                security: wisp.PlainText,
              )
            }
          }
        }
        _ -> wisp.bad_request()
      }
    }
  }
}

fn handle_logout(req: Request, ctx: Context) -> Response {
  use user <- auth_guard(ctx)
  case auth.delete_session(ctx.auth, user.session.id) {
    Error(err) -> {
      io.debug(err)
      wisp.internal_server_error()
    }
    Ok(_) ->
      wisp.redirect("/login")
      |> wisp.set_cookie(
        request: req,
        name: session_cookie_name,
        value: "",
        max_age: 0,
        security: wisp.PlainText,
      )
  }
}
