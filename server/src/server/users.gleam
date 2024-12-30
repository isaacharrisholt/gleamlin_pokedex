import gleam/http.{Get}
import gleam/string_tree
import lustre/element
import lustre/element/html
import pevensie/auth
import server/context.{type Context, Context}
import server/scaffold.{page_scaffold}
import wisp.{type Request, type Response}

pub fn users_handler(req: Request, path: List(String), ctx: Context) -> Response {
  case path, req.method {
    [user_id], Get -> handle_view_user(req, ctx, user_id)
    _, _ -> wisp.not_found()
  }
}

fn handle_view_user(_req: Request, ctx: Context, user_id: String) -> Response {
  let user_result = auth.get_user_by_id(ctx.auth, user_id)

  case user_result {
    Error(auth.GotTooFewRecords) -> wisp.not_found()
    Error(_) -> wisp.internal_server_error()
    Ok(user) -> {
      let view =
        page_scaffold(
          html.div([], [html.h1([], [html.text(user.user_metadata.name)])]),
        )

      wisp.html_response(
        element.to_document_string(view) |> string_tree.from_string,
        200,
      )
    }
  }
}
