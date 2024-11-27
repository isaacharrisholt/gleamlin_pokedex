import gleam/http.{Get}
import gleam/string_tree
import lustre/attribute
import lustre/element
import lustre/element/html
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
    _, _ -> wisp.not_found()
  }
}

fn handle_account_page(_req: Request, ctx: Context) -> Response {
  use user <- server_auth.auth_guard(ctx)
  let view =
    page_scaffold(
      html.div([], [
        html.h1([], [html.text("Account")]),
        html.p([], [html.text("Logged in as " <> user.user.email)]),
        html.form([attribute.method("post"), attribute.action("/auth/logout")], [
          html.button([attribute.type_("submit")], [html.text("Log out")]),
        ]),
      ]),
    )

  wisp.html_response(
    element.to_document_string(view) |> string_tree.from_string,
    200,
  )
}
