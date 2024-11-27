import lustre/attribute
import lustre/element
import lustre/element/html

pub fn page_scaffold(content: element.Element(a)) -> element.Element(a) {
  html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
      html.title([], "Pokedex"),
    ]),
    html.body([], [content]),
  ])
}
