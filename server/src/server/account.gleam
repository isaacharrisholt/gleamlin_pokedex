import gleam/http.{Get, Post}
import gleam/string_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import pevensie/auth
import server/auth as server_auth
import server/context.{type Context}
import server/scaffold.{page_scaffold}
import wisp.{type Request, type Response}

pub fn account_handler(
  req: Request,
  path: List(String),
  ctx: Context,
) -> Response {
  case path, req.method {
    [], Get -> handle_account_page(req, ctx)
    [], Post -> handle_update_account(req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn handle_account_page(_req: Request, ctx: Context) -> Response {
  use user <- server_auth.auth_guard(ctx)
  let view =
    page_scaffold(
      html.div([], [
        html.h1([], [html.text("Account")]),
        html.p([], [
          html.text(
            "Logged in as "
            <> case user.user.user_metadata.name {
              "" -> user.user.email
              name -> name
            },
          ),
        ]),
        html.div([], [
          html.h2([], [html.text("Update account")]),
          html.form([attribute.method("post"), attribute.action("/account")], [
            html.input([
              attribute.name("name"),
              attribute.placeholder("Name"),
              attribute.type_("text"),
              attribute.value(user.user.user_metadata.name),
            ]),
            html.button([attribute.type_("submit")], [html.text("Update")]),
          ]),
        ]),
        html.a([attribute.href("/auth/logout")], [
          html.button([attribute.type_("submit")], [html.text("Log out")]),
        ]),
      ]),
    )

  wisp.html_response(
    element.to_document_string(view) |> string_tree.from_string,
    200,
  )
}

fn handle_update_account(req: Request, ctx: Context) -> Response {
  use user <- server_auth.auth_guard(ctx)
  use form <- wisp.require_form(req)

  case form.values {
    [#("name", name)] -> {
      case name {
        "" -> wisp.bad_request()
        _ -> {
          let auth_result =
            auth.update_user(
              ctx.auth,
              user.user.id,
              auth.UserUpdate(
                ..auth.default_user_update(),
                user_metadata: auth.Set(context.UserMetadata(name: name)),
              ),
            )

          case auth_result {
            Ok(_) -> wisp.redirect("/account")
            Error(_) -> wisp.internal_server_error()
          }
        }
      }
    }
    _ -> wisp.bad_request()
  }
}
