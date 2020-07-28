module String.Template exposing (render)

import Dict
import Regex exposing (Regex)


{-| Inject values into a template string with the given key-value pairs.

    "Good day ${title} ${lastName}!"
        |> String.Template.render
            [ ( "title", "dr." )
            , ( "lastName", "Who" )
            ]

    -- "Good day dr. Who!"

-}
render : List ( String, String ) -> String -> String
render replacements template =
    let
        dict =
            Dict.fromList replacements
    in
    template
        |> Regex.replace regex
            (\{ match } ->
                let
                    placeholderName =
                        match
                            |> String.dropLeft 2
                            |> String.dropRight 1
                            |> String.toList
                            |> dropWhile ((==) ' ')
                            |> dropWhileRight ((==) ' ')
                            |> String.fromList
                in
                Dict.get placeholderName dict
                    |> Maybe.withDefault match
            )


regex : Regex
regex =
    Regex.fromString "\\${[^}]*}"
        |> Maybe.withDefault Regex.never



-- dropwWhile and dropWhileRight taken from elm-community/list-extra


dropWhile : (a -> Bool) -> List a -> List a
dropWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                dropWhile predicate xs

            else
                list


dropWhileRight : (a -> Bool) -> List a -> List a
dropWhileRight p =
    List.foldr
        (\x xs ->
            if p x && List.isEmpty xs then
                []

            else
                x :: xs
        )
        []
