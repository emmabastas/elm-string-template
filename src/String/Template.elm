module String.Template exposing (inject)

{-|

@docs inject

-}

import Dict exposing (Dict)
import Regex exposing (Regex)


{-| Inject values into a template string with the given key-value pairs.

    "Merry Christmas, ${title}. ${lastName}"
        |> String.Template.inject
            [ ( "title", "Mr" )
            , ( "lastName", "Lawrence" )
            ]

    -- Merry Christmas, Mr. Lawrence

-}
inject : List ( String, String ) -> String -> String
inject substitutions template =
    let
        dict : Dict String String
        dict =
            Dict.fromList substitutions

        regex : Regex
        regex =
            Regex.fromString "\\${[^}]*}"
                |> Maybe.withDefault Regex.never
    in
    template
        |> Regex.replace regex
            (\{ match } ->
                let
                    placeholderName =
                        match
                            |> String.dropLeft 2
                            |> String.dropRight 1
                in
                Dict.get placeholderName dict
                    |> Maybe.withDefault match
            )
