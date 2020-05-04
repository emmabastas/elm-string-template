module String.Template exposing (render)

import Dict
import Regex exposing (Regex)


{-| Inject values into a template string with the given key-value pairs.

    "Good day ${title} ${lastName}."
        |> String.Template [ ( "title", "dr." ), ( "lastName", "Smith" ) ]

    -- "Good day dr. Smith."

-}
render : List ( String, String ) -> String -> String
render replacements template =
    let
        dict =
            Dict.fromList replacements
    in
    template
        |> Regex.replace regex
            (\match ->
                case match.submatches of
                    [ Just placeholderName ] ->
                        Dict.get placeholderName dict
                            |> Maybe.withDefault match.match

                    _ ->
                        match.match
            )


regex : Regex
regex =
    Regex.fromString "\\${[ ]*([^}]*?)[ ]*}"
        |> Maybe.withDefault Regex.never
