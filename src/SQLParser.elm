module SQLParser exposing (Point, parse)

import Parser exposing (Parser, (|.), (|=), succeed, symbol, float, spaces)

type alias Point =
  { x : Float
  , y : Float
  }

point : Parser Point
point =
  succeed Point
    |. symbol "("
    |. spaces
    |= float
    |. spaces
    |. symbol ","
    |. spaces
    |= float
    |. spaces
    |. symbol ")"

parse : String -> Result (List Parser.DeadEnd) Point
parse text = Parser.run point text