module String.Template exposing (inject, injectSafe, Error)

{-| There's two functions to inject values into a string. `inject` and `injectSafe`.

  - `inject` is meant for a static template and key-value pairs.
  - `injectingSafe` can be used with dynamic data where some placeholders might miss values to inject. In that case an `Error` will be returned detailing the problem.

@docs inject, injectSafe, Error

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


{-| Inject values into a string with the given key-value pairs. This function checks that each placeholder has been replaced with a value and is thus suitable for cases where the template and/or key-vaue pairs are dynamic.

    "Good day ${title} ${lastName}!"
        |> String.Template.injectSafe
            [ ( "title", "dr.")
            ] -- We forgot "lastName"

    -- Err [ { placeholderName = "lastName", placeholderRange = (18, 29) } ]

-}
injectSafe : List ( String, String ) -> String -> Result (List Error) String
injectSafe substitutions template =
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


{-| The error returned by `injectingSafe`.
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
