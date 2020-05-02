# String.Interpolate

Put values in your strings, this is a more readable alternative to string concatenation.

```elm
import String.Interpolate


-- Can be hard to understand
greet1 : { name : String, notifications : Int } -> String
greet1 { name, notifications } =
    "Hey " ++ name ++ ". You have " ++ String.fromInt notifications ++ " new notifications."


-- Easier to understand
greet2 : { name : String, notifications : Int } -> String
greet2 { name, notifications } =
    "Hey ${name}. You have ${notifications} new notifications."
        |> String.Interpolate.interpolate
            [ ( "name", name )
            , ( "notifications", String.fromInt notifications )
            ]
```


## Caveats

While a function like `interpolate` can make code more
readable than normal concatenation it is not as safe. For instance, if your template or keys happen to have a typo in them you won't get any help from the compiler!

```elm
"Hello ${naem}!"
    |> interpolate [ ( "name", "Alice" ) ]

-- We expect: "Hello Alice!"
-- We get:    "Hello ${naem}!"
```

Be mindful of this!
[review-string-interpolate](https://package.elm-lang.org/packages/hugobastas/review-string-interpolate/latest)
together with [elm-review](https://github.com/jfmengels/elm-review)
ensures that you wont have any problems like that. It might be worth checking it out!

If you come from a language like JavaScript with first-class template literals
you might be anoyed that Elm lacks this and want to emulate it with this package.
That might not be worth the trouble! If the strings are small then normal
concatenation isn't that bad.
Elm's aproach is always to __Make things right, Not right now.__


## Alternatives

There's already two packages availible to deal with interpolation.
It's up to you to decide which package to pick (and if you need one in the
first place).
But here is why I chose to make my own package instead of using one of the other
two:

* [lukewestby/elm-string-interpolate](https://package.elm-lang.org/packages/lukewestby/elm-string-interpolate/latest/) 
has no way to give the placeholders in your tamplete descriptive names.
Your template would look like this: `"Hello {0} {1}!"` instead of:
`"Hello ${firstName} ${lastName}!"`.

* [jorgengranseth/elm-string-format](https://package.elm-lang.org/packages/jorgengranseth/elm-string-format/latest/)
is pretty nice, it has named placeholders.
The only thing it doesn't have is an `elm-review` rule removing
the risk of typos etc. If you interpolate very large strings with many placeholders
many times a second `elm-string-format` will also be slower.
Anything else is just personal preference!
