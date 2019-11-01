module SQLParser exposing (Point, parse)

import Dict exposing (Dict)
import Parser
    exposing
        ( (|.)
        , (|=)
        , Nestable(..)
        , Parser
        , Step(..)
        , andThen
        , chompIf
        , chompWhile
        , end
        , float
        , getChompedString
        , getOffset
        , lineComment
        , loop
        , map
        , mapChompedString
        , multiComment
        , oneOf
        , problem
        , succeed
        , token
        )
import Regex exposing (Regex)
import Set exposing (Set)


type alias Point =
    { x : Float
    , y : Float
    }


type Token
    = Dot
    | Invalid String
    | Hex String
    | Int String
    | Float Float
    | String String
    | Parameter String
    | Identifier String
    | Keyword String
    | Operator String
    | Meaningless String


type alias BoundsToken =
    { start : Int
    , token : Token
    , stop : Int
    }


sqlToken : Parser BoundsToken
sqlToken =
    loop ()
        (\_ ->
            oneOf
                [ succeed (Loop ())
                    |. oneOf
                        [ chompIf isWhitespace
                            |> andThen (\_ -> chompWhile isWhitespace)
                        , lineComment "--"
                        , multiComment "/*" "*/" NotNestable
                        ]
                , map Done sqlTokenWithNoWhitespace
                ]
        )


sqlTokenWithNoWhitespace : Parser BoundsToken
sqlTokenWithNoWhitespace =
    succeed BoundsToken
        |= getOffset
        |= sqlTokenWithNoBounds
        |= getOffset


sqlTokenWithNoBounds : Parser Token
sqlTokenWithNoBounds =
    oneOf
        [ mapChompedString interpretFloat float
            |= getChompedString (chompWhile isIdentifierChar)
        , succeed String
            |. token "'"
            |= loop [] (stringLoop '\'')
        , succeed Parameter
            |= getChompedString
                (oneOf
                    [ token "@"
                    , token ":"
                    , token "$"
                    , token "#"
                    , token "?"
                    ]
                    |. loop () parameterLoop
                )
        , succeed Identifier
            |. token "`"
            |= loop [] (stringLoop '`')
        , succeed Identifier
            |. token "\""
            |= loop [] (stringLoop '"')
            -- work around syntax highlighting bug
            |. succeed '"'
        , succeed Identifier
            |. token "["
            |= getChompedString
                (chompWhile ((/=) ']'))
            |. oneOf [ token "]", end ]
        , map keywordOrIdentifier
            (getChompedString
                (chompIf isIdentifierChar
                    |. chompWhile isIdentifierChar
                )
            )
        , succeed (Operator "NE") |. token "!="
        , succeed (Operator "LE") |. token "<="
        , succeed (Operator "NE") |. token "<>"
        , succeed (Operator "LSHIFT") |. token "<<"
        , succeed (Operator "EQ") |. token "=="
        , succeed (Operator "GE") |. token ">="
        , succeed (Operator "RSHIFT") |. token ">>"
        , succeed (Operator "CONCAT") |. token "||"
        , getChompedString (chompIf (always True))
            |> andThen singleCharacterToken
        ]


stringLoop : Char -> List String -> Parser (Step (List String) String)
stringLoop delimiter segments =
    let
        delimiterString =
            String.fromChar delimiter
    in
    getChompedString (chompWhile ((/=) delimiter))
        |> andThen
            (\segment ->
                oneOf
                    [ succeed (Loop (segment :: segments))
                        |. token (delimiterString ++ delimiterString)
                    , succeed
                        (Done
                            (String.join
                                delimiterString
                                (segment :: segments)
                            )
                        )
                        |. oneOf [ token delimiterString, end ]
                    ]
            )


parameterLoop : () -> Parser (Step () ())
parameterLoop _ =
    succeed identity
        |. chompWhile isIdentifierChar
        |= oneOf
            [ succeed (Loop ())
                |. token "::"
            , succeed (Done ())
            ]


isIdentifierChar : Char -> Bool
isIdentifierChar c =
    Char.isAlphaNum c
        || c
        == '_'
        || c
        == '$'
        || Char.toCode c
        > 0x7F


isWhitespace : Char -> Bool
isWhitespace c =
    List.member c [ ' ', '\n', '\t', '\u{000D}', '\u{000C}' ]


interpretFloat : String -> Float -> String -> Token
interpretFloat floatString parsedFloat subsequentIdentifier =
    if String.isEmpty subsequentIdentifier then
        if
            String.isEmpty
                (String.filter (not << Char.isDigit) floatString)
        then
            Int floatString

        else
            Float parsedFloat

    else if
        floatString
            == "0"
            && Regex.contains hexRegex subsequentIdentifier
    then
        Hex (String.toLower (String.dropLeft 1 subsequentIdentifier))

    else
        Invalid (floatString ++ subsequentIdentifier)


hexRegex : Regex
hexRegex =
    Maybe.withDefault Regex.never <|
        Regex.fromStringWith
            { caseInsensitive = True, multiline = False }
            "^x[0-9a-f]$"


parse : String -> Result (List Parser.DeadEnd) Point
parse text =
    Parser.run (succeed { x = 3, y = 5 }) text


keywordOrIdentifier : String -> Token
keywordOrIdentifier word =
    case Dict.get (String.toUpper word) keywordNames of
        Nothing ->
            Identifier word

        Just name ->
            Keyword name


keywordNames : Dict String String
keywordNames =
    Dict.fromList
        [ ( "ABORT", "ABORT" )
        , ( "ADD", "ADD" )
        , ( "AFTER", "AFTER" )
        , ( "ALL", "ALL" )
        , ( "ALTER", "ALTER" )
        , ( "ANALYZE", "ANALYZE" )
        , ( "AND", "AND" )
        , ( "AS", "AS" )
        , ( "ASC", "ASC" )
        , ( "ATTACH", "ATTACH" )
        , ( "AUTOINCREMENT", "AUTOINCR" )
        , ( "BEFORE", "BEFORE" )
        , ( "BEGIN", "BEGIN" )
        , ( "BETWEEN", "BETWEEN" )
        , ( "BY", "BY" )
        , ( "CASCADE", "CASCADE" )
        , ( "CASE", "CASE" )
        , ( "CAST", "CAST" )
        , ( "CHECK", "CHECK" )
        , ( "COLLATE", "COLLATE" )
        , ( "COLUMN", "COLUMNKW" )
        , ( "COMMIT", "COMMIT" )
        , ( "CONFLICT", "CONFLICT" )
        , ( "CONSTRAINT", "CONSTRAINT" )
        , ( "CREATE", "CREATE" )
        , ( "CROSS", "JOIN_KW" )
        , ( "CURRENT_DATE", "CTIME_KW" )
        , ( "CURRENT_TIME", "CTIME_KW" )
        , ( "CURRENT_TIMESTAMP", "CTIME_KW" )
        , ( "DATABASE", "DATABASE" )
        , ( "DEFAULT", "DEFAULT" )
        , ( "DEFERRED", "DEFERRED" )
        , ( "DEFERRABLE", "DEFERRABLE" )
        , ( "DELETE", "DELETE" )
        , ( "DESC", "DESC" )
        , ( "DETACH", "DETACH" )
        , ( "DISTINCT", "DISTINCT" )
        , ( "DROP", "DROP" )
        , ( "END", "END" )
        , ( "EACH", "EACH" )
        , ( "ELSE", "ELSE" )
        , ( "ESCAPE", "ESCAPE" )
        , ( "EXCEPT", "EXCEPT" )
        , ( "EXCLUSIVE", "EXCLUSIVE" )
        , ( "EXISTS", "EXISTS" )
        , ( "EXPLAIN", "EXPLAIN" )
        , ( "FAIL", "FAIL" )
        , ( "FOR", "FOR" )
        , ( "FOREIGN", "FOREIGN" )
        , ( "FROM", "FROM" )
        , ( "FULL", "JOIN_KW" )
        , ( "GLOB", "GLOB" )
        , ( "GROUP", "GROUP" )
        , ( "HAVING", "HAVING" )
        , ( "IF", "IF" )
        , ( "IGNORE", "IGNORE" )
        , ( "IMMEDIATE", "IMMEDIATE" )
        , ( "IN", "IN" )
        , ( "INDEX", "INDEX" )
        , ( "INITIALLY", "INITIALLY" )
        , ( "INNER", "JOIN_KW" )
        , ( "INSERT", "INSERT" )
        , ( "INSTEAD", "INSTEAD" )
        , ( "INTERSECT", "INTERSECT" )
        , ( "INTO", "INTO" )
        , ( "IS", "IS" )
        , ( "ISNULL", "ISNULL" )
        , ( "JOIN", "JOIN" )
        , ( "KEY", "KEY" )
        , ( "LEFT", "JOIN_KW" )
        , ( "LIKE", "LIKE" )
        , ( "LIMIT", "LIMIT" )
        , ( "MATCH", "MATCH" )
        , ( "NATURAL", "JOIN_KW" )
        , ( "NOT", "NOT" )
        , ( "NOTNULL", "NOTNULL" )
        , ( "NULL", "NULL" )
        , ( "OF", "OF" )
        , ( "OFFSET", "OFFSET" )
        , ( "ON", "ON" )
        , ( "OR", "OR" )
        , ( "ORDER", "ORDER" )
        , ( "OUTER", "JOIN_KW" )
        , ( "PLAN", "PLAN" )
        , ( "PRAGMA", "PRAGMA" )
        , ( "PRIMARY", "PRIMARY" )
        , ( "QUERY", "QUERY" )
        , ( "RAISE", "RAISE" )
        , ( "REFERENCES", "REFERENCES" )
        , ( "REGEXP", "REGEXP" )
        , ( "REINDEX", "REINDEX" )
        , ( "RENAME", "RENAME" )
        , ( "REPLACE", "REPLACE" )
        , ( "RESTRICT", "RESTRICT" )
        , ( "RIGHT", "JOIN_KW" )
        , ( "ROLLBACK", "ROLLBACK" )
        , ( "ROW", "ROW" )
        , ( "SELECT", "SELECT" )
        , ( "SET", "SET" )
        , ( "TABLE", "TABLE" )
        , ( "TEMP", "TEMP" )
        , ( "TEMPORARY", "TEMP" )
        , ( "THEN", "THEN" )
        , ( "TO", "TO" )
        , ( "TRANSACTION", "TRANSACTION" )
        , ( "TRIGGER", "TRIGGER" )
        , ( "UNION", "UNION" )
        , ( "UNIQUE", "UNIQUE" )
        , ( "UPDATE", "UPDATE" )
        , ( "USING", "USING" )
        , ( "VACUUM", "VACUUM" )
        , ( "VALUES", "VALUES" )
        , ( "VIEW", "VIEW" )
        , ( "VIRTUAL", "VIRTUAL" )
        , ( "WHEN", "WHEN" )
        , ( "WHERE", "WHERE" )
        ]


singleCharacterToken : String -> Parser Token
singleCharacterToken s =
    case String.toList s of
        [ c ] ->
            case Dict.get c operatorNames of
                Just name ->
                    succeed (Operator name)

                Nothing ->
                    let
                        code =
                            Char.toCode c
                    in
                    if
                        code
                            < 0x08
                            || (code >= 0x0E && code < 20)
                            || List.member
                                c
                                [ '\\', '^', '{', '}', '\u{007F}' ]
                    then
                        succeed (Meaningless s)

                    else
                        problem ("unknown character: " ++ s)

        _ ->
            problem ("unknown character: " ++ s)


operatorNames : Dict Char String
operatorNames =
    Dict.fromList
        [ ( '-', "MINUS" )
        , ( '(', "LP" )
        , ( ')', "RP" )
        , ( ';', "SEMI" )
        , ( '+', "PLUS" )
        , ( '*', "STAR" )
        , ( '/', "SLASH" )
        , ( '%', "REM" )
        , ( '=', "EQ" )
        , ( '<', "LT" )
        , ( '>', "GT" )
        , ( ',', "COMMA" )
        , ( '&', "BITAND" )
        , ( '~', "BITNOT" )
        , ( '|', "BITOR" )
        , ( '.', "DOT" )
        ]
