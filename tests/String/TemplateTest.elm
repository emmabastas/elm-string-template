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



-- Fuzzers


placeholderFuzzer : Fuzzer { placeholder : String, name : String }
placeholderFuzzer =
    Fuzz.map
        (\name -> { placeholder = "${" ++ name ++ "}", name = name })
        placeholderNameFuzzer


placeholderNameFuzzer : Fuzzer String
placeholderNameFuzzer =
    Fuzz.string
        |> Fuzz.map (String.replace "}" "")
