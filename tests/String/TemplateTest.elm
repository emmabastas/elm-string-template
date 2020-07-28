module String.TemplateTest exposing (all)

import Dict
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import String.Template exposing (Error, inject, injectSafe)
import Test exposing (Test, concat, describe, fuzz, test)


all : Test
all =
    concat
        [ identifiesPlaceholdersTests
        , identifiesPlaceholderNamesTest
        , dealsWithMultiplePlaceholders
        ]


identifiesPlaceholdersTests : Test
identifiesPlaceholdersTests =
    describe "Identifies placeholders"
        [ injectAndInjectSafeTest "${}"
            { template = "${}"
            , toInject = [ ( "", "x" ) ]
            , injectExpect = Expect.equal "x"
            , injectSafeExpect = Expect.equal (Ok "x")
            }
        , injectAndInjectSafeTest "$${}}"
            { template = "$${}}"
            , toInject = [ ( "", "x" ) ]
            , injectExpect = Expect.equal "$x}"
            , injectSafeExpect = Expect.equal (Ok "$x}")
            }
        , injectAndInjectSafeTest "\\${}"
            { template = "\\${}"
            , toInject = [ ( "", "x" ) ]
            , injectExpect = Expect.equal "\\x"
            , injectSafeExpect = Expect.equal (Ok "\\x")
            }
        , injectAndInjectSafeTest "Whitespace characters" <|
            { template = "\n${} "
            , toInject = [ ( "", "x" ) ]
            , injectExpect = Expect.equal "\nx "
            , injectSafeExpect = Expect.equal (Ok "\nx ")
            }
        , injectAndInjectSafeFuzz "Random characters that won't form a placeholder" <|
            Fuzz.map2
                (\pre post ->
                    { template = pre ++ "${}" ++ post
                    , toInject = [ ( "", "x" ) ]
                    , injectExpect = Expect.equal (pre ++ "x" ++ post)
                    , injectSafeExpect = Expect.equal (Ok (pre ++ "x" ++ post))
                    }
                )
                stringWithoutPlaceholderStart
                stringWithoutPlaceholderStart
        ]


identifiesPlaceholderNamesTest : Test
identifiesPlaceholderNamesTest =
    describe "Identifies placeholders names"
        [ injectAndInjectSafeTest "${x}"
            { template = "${x}"
            , toInject = [ ( "x", "y" ) ]
            , injectExpect = Expect.equal "y"
            , injectSafeExpect = Expect.equal (Ok "y")
            }
        , injectAndInjectSafeTest "${foo}"
            { template = "${foo}"
            , toInject = [ ( "foo", "bar" ) ]
            , injectExpect = Expect.equal "bar"
            , injectSafeExpect = Expect.equal (Ok "bar")
            }
        , injectAndInjectSafeTest "ASCII-space is trimmed from name"
            { template = "${  \nfoo  }"
            , toInject = [ ( "\nfoo", "bar" ) ]
            , injectExpect = Expect.equal "bar"
            , injectSafeExpect = Expect.equal (Ok "bar")
            }
        , injectAndInjectSafeTest "Name can contain non leading and trailing ASCII-space"
            { template = "${foo bar}"
            , toInject = [ ( "foo bar", "baz" ) ]
            , injectExpect = Expect.equal "baz"
            , injectSafeExpect = Expect.equal (Ok "baz")
            }
        , injectAndInjectSafeTest "Name can contain unicode"
            { template = "${foõ}"
            , toInject = [ ( "foõ", "bar" ) ]
            , injectExpect = Expect.equal "bar"
            , injectSafeExpect = Expect.equal (Ok "bar")
            }
        , injectAndInjectSafeTest "Name can contain `${`" <|
            { template = "${${}"
            , toInject = [ ( "${", "foo" ) ]
            , injectExpect = Expect.equal "foo"
            , injectSafeExpect = Expect.equal (Ok "foo")
            }
        , injectAndInjectSafeFuzz "Random valid placeholder name" <|
            Fuzz.map3
                (\name leadingSpace trailingSpace ->
                    { template = "${" ++ leadingSpace ++ name ++ trailingSpace ++ "}"
                    , toInject = [ ( name, "foo" ) ]
                    , injectExpect = Expect.equal "foo"
                    , injectSafeExpect = Expect.equal (Ok "foo")
                    }
                )
                validPlaceholderName
                (Fuzz.list (Fuzz.constant ' ') |> Fuzz.map String.fromList)
                (Fuzz.list (Fuzz.constant ' ') |> Fuzz.map String.fromList)
        ]


dealsWithMultiplePlaceholders : Test
dealsWithMultiplePlaceholders =
    describe "Deals with multiple placeholders"
        [ injectAndInjectSafeTest "Inject into multiple placeholders with same name" <|
            { template = "${}${}"
            , toInject = [ ( "", "foo" ) ]
            , injectExpect = Expect.equal "foofoo"
            , injectSafeExpect = Expect.equal (Ok "foofoo")
            }
        , dealsWithMultipleUniquePlaceholders
        ]


dealsWithMultipleUniquePlaceholders : Test
dealsWithMultipleUniquePlaceholders =
    injectAndInjectSafeFuzz "Deals with multiple unique placeholders" <|
        let
            placeholderElement :
                Fuzzer
                    { element : String
                    , injectElement : String -> String
                    , name : String
                    }
            placeholderElement =
                Fuzz.map5
                    (\name leadingSpace trailingSpace pre post ->
                        { element = " " ++ pre ++ "${" ++ leadingSpace ++ name ++ trailingSpace ++ "}" ++ post
                        , injectElement = \s -> " " ++ pre ++ s ++ post
                        , name = name
                        }
                    )
                    validPlaceholderName
                    (Fuzz.list (Fuzz.constant ' ') |> Fuzz.map String.fromList)
                    (Fuzz.list (Fuzz.constant ' ') |> Fuzz.map String.fromList)
                    stringWithoutPlaceholderStart
                    stringWithoutPlaceholderStart

            placeholderElements =
                Fuzz.map
                    (\elements ->
                        elements
                            |> List.map
                                (\{ element, injectElement, name } ->
                                    ( name, ( element, injectElement ) )
                                )
                            |> Dict.fromList
                            |> Dict.toList
                            |> List.map
                                (\( name, ( element, injectElement ) ) ->
                                    { element = element
                                    , injectElement = injectElement
                                    , name = name
                                    }
                                )
                    )
                    (Fuzz.list placeholderElement)
        in
        Fuzz.map
            (\elements ->
                { template = List.map .element elements |> String.concat
                , toInject =
                    List.indexedMap
                        (\i { name } -> ( name, String.fromInt i ))
                        elements
                , injectExpect =
                    elements
                        |> List.indexedMap
                            (\i { injectElement } -> injectElement (String.fromInt i))
                        |> String.concat
                        |> Expect.equal
                , injectSafeExpect =
                    elements
                        |> List.indexedMap
                            (\i { injectElement } -> injectElement (String.fromInt i))
                        |> String.concat
                        |> Ok
                        |> Expect.equal
                }
            )
            placeholderElements


validPlaceholderName : Fuzzer String
validPlaceholderName =
    (Fuzz.list << Fuzz.oneOf)
        ([ '$', '{', ' ', '\n', 'õ' ]
            |> List.map Fuzz.constant
        )
        |> Fuzz.map String.fromList
        |> Fuzz.map trimASCIISpace


stringWithoutPlaceholderStart : Fuzzer String
stringWithoutPlaceholderStart =
    (Fuzz.list << Fuzz.oneOf)
        ([ '$', '{', ' ', '\n', 'õ' ]
            |> List.map Fuzz.constant
        )
        |> Fuzz.map String.fromList
        |> Fuzz.map removePlaceholderStart


removePlaceholderStart : String -> String
removePlaceholderStart s =
    let
        ns =
            String.replace "${" "" s
    in
    if s == ns then
        s

    else
        removePlaceholderStart ns


trimASCIISpace : String -> String
trimASCIISpace s =
    if String.startsWith " " s then
        trimASCIISpace (String.slice 1 (String.length s) s)

    else if String.endsWith " " s then
        trimASCIISpace (String.slice 0 (String.length s - 1) s)

    else
        s


injectAndInjectSafeTest :
    String
    ->
        { template : String
        , toInject : List ( String, String )
        , injectExpect : String -> Expectation
        , injectSafeExpect : Result (List Error) String -> Expectation
        }
    -> Test
injectAndInjectSafeTest desc { template, toInject, injectExpect, injectSafeExpect } =
    describe desc
        [ test "String.Template.inject" <|
            \_ -> inject toInject template |> injectExpect
        , test "String.Template.injectSafe" <|
            \_ -> injectSafe toInject template |> injectSafeExpect
        ]


injectAndInjectSafeFuzz :
    String
    ->
        Fuzzer
            { template : String
            , toInject : List ( String, String )
            , injectExpect : String -> Expectation
            , injectSafeExpect : Result (List Error) String -> Expectation
            }
    -> Test
injectAndInjectSafeFuzz desc fuzzer =
    describe desc
        [ fuzz fuzzer "String.Template.inject" <|
            \x -> inject x.toInject x.template |> x.injectExpect
        , fuzz fuzzer "String.Template.injectSafe" <|
            \x -> injectSafe x.toInject x.template |> x.injectSafeExpect
        ]
