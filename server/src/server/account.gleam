import formz
import formz/field
import formz_lustre/definitions
import formz_lustre/simple
import gleam/http.{Get, Post}
import gleam/option.{Some}
import gleam/string_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import pevensie/auth
import pevensie/cache
import server/auth as server_auth
import server/context.{type Context}
import server/scaffold.{page_scaffold}
import server/user.{type UserMetadata, UserMetadata}
import wisp.{type Request, type Response}

pub fn account_handler(
  req: Request,
  path: List(String),
  ctx: Context,
) -> Response {
  case path, req.method {
    [], Get -> handle_account_page(req, ctx)
    [], Post -> handle_update_account(req, ctx)
    // CBA to do client side requests, so can't have Delete method
    ["delete"], Post -> handle_delete_account(req, ctx)
    _, _ -> wisp.not_found()
  }
}

fn account_form(user_metadata: UserMetadata) {
  use name <- formz.require(
    field.field("name")
      |> field.set_label("Name")
      |> field.set_raw_value(user_metadata.name),
    definitions.text_field(),
  )
  use bio <- formz.require(
    field.field("bio")
      |> field.set_label("Bio")
      |> field.set_raw_value(user_metadata.bio),
    definitions.text_field(),
  )

  formz.create_form(UserMetadata(..user_metadata, name:, bio:))
}

fn handle_account_page(_req: Request, ctx: Context) -> Response {
  // These are just here so I can test the cache functions quickly
  let assert Ok(_) =
    cache.set(
      ctx.cache,
      resource_type: "test",
      key: "test",
      value: "test",
      ttl_seconds: Some(10),
    )
  let assert Ok("test") =
    cache.get(ctx.cache, resource_type: "test", key: "test")
  let assert Ok(_) = cache.delete(ctx.cache, resource_type: "test", key: "test")

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
            simple.generate(account_form(user.user.user_metadata)),
            html.button([attribute.type_("submit")], [html.text("Update")]),
          ]),
        ]),
        html.a([attribute.href("/auth/logout")], [
          html.button([attribute.type_("submit")], [html.text("Log out")]),
        ]),
        html.form(
          [attribute.method("post"), attribute.action("/account/delete")],
          [
            html.button([attribute.type_("submit")], [
              html.text("Delete account"),
            ]),
          ],
        ),
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

  let form_result =
    account_form(user.user.user_metadata)
    |> formz.data(form.values)
    |> formz.parse

  case form_result {
    Ok(new_user_metadata) -> {
      case new_user_metadata.name {
        "" -> wisp.bad_request()
        _ -> {
          let auth_result =
            auth.update_user(
              ctx.auth,
              user.user.id,
              auth.UserUpdate(
                ..auth.default_user_update(),
                user_metadata: auth.Set(new_user_metadata),
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

fn handle_delete_account(req: Request, ctx: Context) -> Response {
  use user <- server_auth.auth_guard(ctx)
  let auth_result = auth.delete_user_by_id(ctx.auth, user.user.id)

  case auth_result {
    Ok(_) -> {
      let auth_result = auth.delete_session(ctx.auth, user.session.id)
      case auth_result {
        Ok(_) ->
          wisp.redirect("/")
          |> wisp.set_cookie(
            request: req,
            name: server_auth.session_cookie_name,
            value: "",
            max_age: 0,
            security: wisp.PlainText,
          )
        Error(_) -> wisp.internal_server_error()
      }
    }
    Error(_) -> wisp.internal_server_error()
  }
}
