module String.TemplateTest exposing (suite)

import Expect
import String.Template exposing (inject, injectSafe)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "String.Template"
        [ injectSuite
        , injectSafeSuite
        ]


injectSuite : Test
injectSuite =
    describe "String.Template.inject"
        [ test "Rendering should work" <|
            \_ ->
                "Hey ${name}!"
                    |> inject [ ( "name", "Alice" ) ]
                    |> Expect.equal "Hey Alice!"
        , test "A placeholder should be injected everywhere" <|
            \_ ->
                "Hey ${name}! Hey, hey, Hey ${name}."
                    |> inject [ ( "name", "Mickey" ) ]
                    |> Expect.equal "Hey Mickey! Hey, hey, Hey Mickey."
        , test "If a placeholder doesn't have a matching key it should be left unaltered" <|
            \_ ->
                "Hey ${name}!"
                    |> inject [ ( "foo", "Alice" ) ]
                    |> Expect.equal "Hey ${name}!"
        , test "Leading and trailing ASCII space (U+0020 only) is ignored in a placeholder" <|
            \_ ->
                "Hey ${   name   }!"
                    |> inject [ ( "name", "Alice" ) ]
                    |> Expect.equal "Hey Alice!"
        , test "Leading and trailing non-ASCII space (U+0020) characters aren't ignored" <|
            \_ ->
                "${  \nfoo  \u{000D}}"
                    |> inject [ ( "\nfoo  \u{000D}", "bar" ) ]
                    |> Expect.equal "bar"
        , test "ASCII space is not ignored within a placeholder name" <|
            \_ ->
                "Good day dr. ${ last name }."
                    |> inject [ ( "last name", "Smith" ) ]
                    |> Expect.equal "Good day dr. Smith."
        , test "Any unicode character  except `}` (U+007D) is allowed in a placeholder name" <|
            \_ ->
                "${  ©õ0L \nAme ${  }"
                    |> inject [ ( "©õ0L \nAme ${", "foo" ) ]
                    |> Expect.equal "foo"
        ]


injectSafeSuite : Test
injectSafeSuite =
    describe "String.Template.injectSafe"
        [ test "Rendering should work" <|
            \_ ->
                "Hey ${name}!"
                    |> injectSafe [ ( "name", "Alice" ) ]
                    |> Expect.equal (Ok "Hey Alice!")
        , test "A placeholder should be injected everywhere" <|
            \_ ->
                "Hey ${name}! Hey, hey, Hey ${name}."
                    |> injectSafe [ ( "name", "Mickey" ) ]
                    |> Expect.equal (Ok "Hey Mickey! Hey, hey, Hey Mickey.")
        , test "If a placeholder doesn't have a matching key it should be left unaltered" <|
            \_ ->
                "Hey ${name}!"
                    |> injectSafe [ ( "foo", "Alice" ) ]
                    |> Expect.equal
                        (Err
                            [ { placeholderName = "name"
                              , placeholderRange = ( 4, 11 )
                              }
                            ]
                        )
        , test "Leading and trailing ASCII space (U+0020 only) is ignored in a placeholder" <|
            \_ ->
                "Hey ${   name   }!"
                    |> injectSafe [ ( "name", "Alice" ) ]
                    |> Expect.equal (Ok "Hey Alice!")
        , test "Leading and trailing non-ASCII space (U+0020) characters aren't ignored" <|
            \_ ->
                "${  \nfoo  \u{000D}}"
                    |> injectSafe [ ( "\nfoo  \u{000D}", "bar" ) ]
                    |> Expect.equal (Ok "bar")
        , test "ASCII space is not ignored within a placeholder name" <|
            \_ ->
                "Good day dr. ${ last name }."
                    |> injectSafe [ ( "last name", "Smith" ) ]
                    |> Expect.equal (Ok "Good day dr. Smith.")
        , test "Any unicode character  except `}` (U+007D) is allowed in a placeholder name" <|
            \_ ->
                "${  ©õ0L \nAme ${  }"
                    |> injectSafe [ ( "©õ0L \nAme ${", "foo" ) ]
                    |> Expect.equal (Ok "foo")
        ]
