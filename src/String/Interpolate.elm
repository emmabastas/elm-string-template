module String.Interpolate exposing (interpolate)

import Dict
import Regex exposing (Regex)


{-| Interpolate a string with the given key-value pairs.

    "Good day ${title} ${lastName}."
        |> interpolate [ ( "title", "dr." ), ( "lastName", "Smith" ) ]

    -- "Good day dr. Smith."

-}
interpolate : List ( String, String ) -> String -> String
interpolate replacements template =
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
