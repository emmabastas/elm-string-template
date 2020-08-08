module String.TemplateTest exposing (all)

import Expect
import Fuzz exposing (Fuzzer)
import String.Template exposing (inject)
import Test exposing (Test, concat, describe, fuzz, test)


all : Test
all =
    concat
        [ validPlaceholdersUnitTests
        , validPlaceholdersFuzzTest
        , missingClosingBracketTest
        , withoutAssociatedValueFuzzTest
        , placeholderSuroundedByTextFuzzTest
        ]


validPlaceholdersUnitTests : Test
validPlaceholdersUnitTests =
    describe "Valid placeholder unit tests"
        ([ { template = "${}"
           , toInject = [ ( "", "x" ) ]
           , expect = "x"
           }
         , { template = "${foo}"
           , toInject = [ ( "foo", "bar" ) ]
           , expect = "bar"
           }
         , { template = "${ foo }"
           , toInject = [ ( " foo ", "bar" ) ]
           , expect = "bar"
           }
         , { template = "${${}"
           , toInject = [ ( "${", "foo" ) ]
           , expect = "foo"
           }
         , { template = "$${foo}}"
           , toInject = [ ( "foo", "bar" ) ]
           , expect = "$bar}"
           }
         , { template = "${identity}"
           , toInject = [ ( "identity", "${identity}" ) ]
           , expect = "${identity}"
           }
         ]
            |> List.map
                (\{ template, toInject, expect } ->
                    test template
                        (\_ ->
                            inject toInject template
                                |> Expect.equal expect
                        )
                )
        )


validPlaceholdersFuzzTest : Test
validPlaceholdersFuzzTest =
    fuzz placeholderFuzzer "Valid placeholder fuzz test" <|
        \{ placeholder, name } ->
            inject [ ( name, "foo" ) ] placeholder
                |> Expect.equal "foo"


missingClosingBracketTest : Test
missingClosingBracketTest =
    test "`${` without closing `}` does not form a placeholder" <|
        \_ ->
            "${foo"
                |> inject [ ( "foo", "bar" ) ]
                |> Expect.equal "${foo"


withoutAssociatedValueFuzzTest : Test
withoutAssociatedValueFuzzTest =
    fuzz placeholderFuzzer "Placeholder without associated value is ignored" <|
        \{ placeholder } ->
            inject [] placeholder
                |> Expect.equal placeholder


placeholderSuroundedByTextFuzzTest : Test
placeholderSuroundedByTextFuzzTest =
    fuzz placeholderSuroundedByTextFuzzer
        "Placeholder surounded by text fuzz test"
    <|
        \{ placeholder, name, leadingText, trailingText } ->
            (leadingText ++ placeholder ++ trailingText)
                |> inject [ ( name, "foo" ) ]
                |> Expect.equal (leadingText ++ "foo" ++ trailingText)



-- Fuzzers


placeholderSuroundedByTextFuzzer :
    Fuzzer
        { placeholder : String
        , name : String
        , leadingText : String
        , trailingText : String
        }
placeholderSuroundedByTextFuzzer =
    Fuzz.map3
        (\{ placeholder, name } leadingText trailingText ->
            { placeholder = placeholder
            , name = name
            , leadingText = leadingText
            , trailingText = trailingText
            }
        )
        placeholderFuzzer
        textFuzzer
        textFuzzer


placeholderFuzzer : Fuzzer { placeholder : String, name : String }
placeholderFuzzer =
    Fuzz.map
        (\name -> { placeholder = "${" ++ name ++ "}", name = name })
        placeholderNameFuzzer


placeholderNameFuzzer : Fuzzer String
placeholderNameFuzzer =
    Fuzz.string
        |> Fuzz.map (String.replace "}" "")


textFuzzer : Fuzzer String
textFuzzer =
    Fuzz.string
        |> Fuzz.map (replaceRecursive "${" "")



-- helpers


replaceRecursive : String -> String -> String -> String
replaceRecursive target new string =
    let
        newString =
            String.replace target new string
    in
    if newString == string then
        newString

    else
        replaceRecursive target new newString
