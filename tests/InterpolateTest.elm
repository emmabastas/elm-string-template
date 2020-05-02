module InterpolateTest exposing (suite)

import Expect
import Fuzz
import String.Interpolate exposing (interpolate)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Interpolate"
        [ interpolateLiteralSuite
        ]


interpolateLiteralSuite : Test
interpolateLiteralSuite =
    describe "interpolate"
        [ test "Interpolation should work" <|
            \_ ->
                "Hey ${name}!"
                    |> interpolate [ ( "name", "Alice" ) ]
                    |> Expect.equal "Hey Alice!"
        , test "A placeholder should be interpolated everywhere" <|
            \_ ->
                "Hey ${name}! Hey, hey, Hey ${name}."
                    |> interpolate [ ( "name", "Mickey" ) ]
                    |> Expect.equal "Hey Mickey! Hey, hey, Hey Mickey."
        , test "If a placeholder doesn't have a matching key it should be left unaltered" <|
            \_ ->
                "Hey ${name}!"
                    |> interpolate [ ( "foo", "Alice" ) ]
                    |> Expect.equal "Hey ${name}!"
        , test "Leading and trailing ASCII space (U+0020 only) is ignored in a placeholder" <|
            \_ ->
                "Hey ${   name   }!"
                    |> interpolate [ ( "name", "Alice" ) ]
                    |> Expect.equal "Hey Alice!"
        , test "Leading and trailing non-ASCII space (U+0020) characters aren't ignored" <|
            \_ ->
                "${  \nfoo  \u{000D}}"
                    |> interpolate [ ( "\nfoo  \u{000D}", "bar" ) ]
                    |> Expect.equal "bar"
        , test "ASCII space is not ignored within a placeholder name" <|
            \_ ->
                "Good day dr. ${ last name }."
                    |> interpolate [ ( "last name", "Smith" ) ]
                    |> Expect.equal "Good day dr. Smith."
        , test "Any unicode character  except `}` (U+007D) is allowed in a placeholder name" <|
            \_ ->
                "${  ©õ0L \nAme ${  }"
                    |> interpolate [ ( "©õ0L \nAme ${", "foo" ) ]
                    |> Expect.equal "foo"
        ]
