module String.Template exposing (Error, render, renderSafe)

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
render substitutions template =
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


{-| Sometimes injecting values with `render` can go wrong. Then it's nice to have
this safe alternative
-}
renderSafe : List ( String, String ) -> String -> Result (List Error) String
renderSafe substitutions template =
    let
        dict =
            Dict.fromList substitutions
    in
    template
        |> Regex.find regex
        |> List.foldl
            (\{ match, index } ( errors, s ) ->
                let
                    placeholderName =
                        placeholderNameFromPlaceholder match

                    startIndex =
                        index

                    endIndex =
                        index + String.length match
                in
                case Dict.get placeholderName dict of
                    Just substitution ->
                        ( errors
                        , replaceSlice substitution startIndex endIndex s
                        )

                    Nothing ->
                        ( { placeholderName = placeholderName
                          , placeholderRange = ( startIndex, endIndex )
                          }
                            :: errors
                        , s
                        )
            )
            ( [], template )
        |> (\( errors, renderedTemplate ) ->
                if List.length errors == 0 then
                    Ok renderedTemplate

                else
                    Err errors
           )


{-| When a placeholder lacks a substitution it is recorded as an error
-}
type alias Error =
    { placeholderName : String
    , placeholderRange : ( Int, Int )
    }


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



-- replaceSlice, dropwWhile and dropWhileRight taken from elm-community/list-extra


replaceSlice : String -> Int -> Int -> String -> String
replaceSlice substitution start end string =
    String.slice 0 start string ++ substitution ++ String.slice end (String.length string) string


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
