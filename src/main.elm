import Browser
import Html exposing (Html, Attribute, button, div, textarea, text)
import Html.Events exposing (onClick, onInput)
import SQLParser
import Html.Attributes exposing (..)

main =
  Browser.sandbox { init = init, update = update, view = view }


-- MODEL

type alias Model =
  { num : Int
  , content : String
  }

init : Model
init =
  { num = 0
  , content = "(2, 3)"
  }


-- UPDATE

type Msg = Increment | Decrement | Change String

update : Msg -> Model -> Model
update msg model =
  case msg of
    Increment ->
      { model | num = model.num + 1 }

    Decrement ->
      { model | num = model.num - 1 }

    Change newContent ->
      { model | content = newContent }


-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ button [ onClick Decrement ] [ text "-" ]
    , div [] [ text (String.fromInt model.num) ]
    , button [ onClick Increment ] [ text "+" ]
    , textarea [ placeholder "Text to reverse", value model.content, onInput Change ] []
    , div [] [ text (
      case SQLParser.parse model.content of
        Ok p ->
          Debug.toString p
        Err deadEnds ->
          Debug.toString deadEnds
    ) ]
    ]
