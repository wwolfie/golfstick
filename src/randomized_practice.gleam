import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import prng/random

pub type Cue {
  Cue(name: String, values: List(String))
}

const shot_cues: List(Cue) = [
  Cue(
    name: "Distance",
    values: [
      "10m shorter than normal", "5m shorter than normal",
      " your normal distance", "5m longer than normal", "as far as you can",
    ],
  ),
  Cue(
    name: "Curve",
    values: ["draw", "slight draw", "straight", "slight fade", "fade"],
  ),
  Cue(
    name: "Height",
    values: ["stinger", "lower", "normal height", "heigher", "flop-like"],
  ), Cue(name: "direction", values: ["pull", "straight", "push"]),
]

pub type View {
  WelcomeView
  InputView
  OutputView
}

pub type Model {
  Model(
    view: View,
    number_of_shots_form: String,
    number_of_shots_to_go: Int,
    club_form: ClubNames,
    club_stored: ClubNames,
  )
}

pub type Msg {
  UserClickButton
  UserChangeFirstClubName(String)
  UserChangeSecondClubName(String)
  UserChangeThirdClubName(String)
  UserChangeNumberOfShots(String)
  UserGoesToNextShot
  UserGoesToInput
}

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub type ClubNames {
  ClubNames(first: String, second: String, third: String)
}

fn init(_flags) -> Model {
  Model(
    view: WelcomeView,
    number_of_shots_form: "24",
    number_of_shots_to_go: 0,
    club_form: ClubNames("I9", "I7", "I5"),
    club_stored: ClubNames("", "", ""),
  )
}

fn handle_shots_input(text: String) -> Int {
  case int.parse(text) {
    Ok(value) -> value
    _ -> 24
  }
}

pub fn handle_next_shot(model: Model) -> Model {
  case model.number_of_shots_to_go > 0 {
    False -> Model(..model, view: InputView)
    True ->
      Model(..model, number_of_shots_to_go: model.number_of_shots_to_go - 1)
  }
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserChangeFirstClubName(text) ->
      Model(..model, club_form: ClubNames(..model.club_form, first: text))
    UserChangeSecondClubName(text) ->
      Model(..model, club_form: ClubNames(..model.club_form, second: text))
    UserChangeThirdClubName(text) ->
      Model(..model, club_form: ClubNames(..model.club_form, third: text))
    UserChangeNumberOfShots(text) -> Model(..model, number_of_shots_form: text)
    UserClickButton ->
      Model(
        ..model,
        club_stored: model.club_form,
        number_of_shots_to_go: handle_shots_input(model.number_of_shots_form),
        view: OutputView,
      )
    UserGoesToNextShot -> handle_next_shot(model)
    UserGoesToInput -> Model(..model, view: InputView)
  }
}

pub fn welcome_view(_model: Model) -> element.Element(Msg) {
  html.div([], [
    html.text(
      "Welcome, this the golf range randomized shot selector, to help you train better",
    ),
    html.br([]),
    html.button([event.on_click(UserGoesToInput)], [html.text("Go to input")]),
  ])
}

pub fn input_view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.form([event.on_submit(UserClickButton)], [
      html.text("First club: "),
      html.input([
        attribute.type_("text"),
        attribute.value(model.club_form.first),
        event.on_input(UserChangeFirstClubName),
      ]),
      html.br([]),
      html.text("Second club: "),
      html.input([
        attribute.type_("text"),
        attribute.value(model.club_form.second),
        event.on_input(UserChangeSecondClubName),
      ]),
      html.br([]),
      html.text("Third club: "),
      html.input([
        attribute.type_("text"),
        attribute.value(model.club_form.third),
        event.on_input(UserChangeThirdClubName),
      ]),
      html.br([]),
      html.text("Number of balls to play: "),
      html.input([
        attribute.type_("value"),
        attribute.value(model.number_of_shots_form),
        event.on_input(UserChangeNumberOfShots),
      ]),
      html.br([]),
      html.input([attribute.type_("submit"), attribute.value("start playing")]),
    ]),
  ])
}

pub fn select_random_club(model: Model) -> String {
  case random.random_sample(random.int(1, 3)) {
    1 -> model.club_stored.first
    2 -> model.club_stored.second
    _ -> model.club_stored.third
  }
}

pub fn select_random_cue(cue: Cue) -> String {
  let idx = random.random_sample(random.int(0, list.length(cue.values) - 1))
  let assert Ok(value) =
    cue.values
    |> list.drop(idx)
    |> list.first
  value
}

pub fn make_cues_text() -> List(element.Element(Msg)) {
  shot_cues
  |> list.map(fn(cue: Cue) {
    let value = select_random_cue(cue)
    html.text(cue.name <> ": " <> value)
  })
  |> list.intersperse(html.br([]))
}

pub fn output_view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.text(
      "There are "
      <> int.to_string(model.number_of_shots_to_go)
      <> " out of "
      <> model.number_of_shots_form
      <> " shots to go",
    ),
    html.br([]),
    html.text("Hit your: " <> select_random_club(model)),
    html.div([], make_cues_text()),
    html.br([]),
    html.button([event.on_click(UserGoesToNextShot)], [
      html.text("Return to input"),
    ]),
  ])
}

pub fn view(model: Model) -> element.Element(Msg) {
  case model.view {
    WelcomeView -> welcome_view(model)
    InputView -> input_view(model)
    OutputView -> output_view(model)
  }
}
