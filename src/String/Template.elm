module String.Template exposing (inject)

{-|

@docs inject

-}

import Dict
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
        dict =
            Dict.fromList substitutions
    in
    template
        |> Regex.replace regex
            (\{ match } ->
                let
                    placeholderName =
                        placeholderNameFromPlaceholder match
                in
                Dict.get placeholderName dict
                    |> Maybe.withDefault match
            )


regex : Regex
regex =
    Regex.fromString "\\${[^}]*}"
        |> Maybe.withDefault Regex.never


placeholderNameFromPlaceholder : String -> String
placeholderNameFromPlaceholder placeholder =
    placeholder
        |> String.dropLeft 2
        |> String.dropRight 1
        |> String.toList
        |> dropWhile ((==) ' ')
        |> dropWhileRight ((==) ' ')
        |> String.fromList



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
