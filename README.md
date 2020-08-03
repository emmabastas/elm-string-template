# String.Template [![Build Status](https://travis-ci.org/emmabastas/elm-string-template.svg?branch=master)](https://travis-ci.org/emmabastas/elm-string-template)
Put values into template strings. Avoid unreadable string concatenation.

```elm
import String.Template


-- String concatenation, hard do understand ://
greet1 : User -> String
greet1 user =
    "Hey " ++ user.name ++ ". You have " ++ String.fromInt user.notifications ++ " new notifications."


-- With this package, easier to get an overview of what's happening
greet2 : User -> String
greet2 user =
    "Hey ${name}. You have ${notifications} new notifications."
        |> String.Template.inject
            [ ( "name", user.name )
            , ( "notifications", String.fromInt user.notifications )
            ]
```


## Caveats

While a function like `String.Template.inject` can make code more
readable than normal concatenation it is not as safe. For instance, if your template or keys happen to have a typo in them you won't get any help from the compiler!

```elm
"Hello ${naem}!"
    |> String.Template.inject [ ( "name", "Alice" ) ]

-- We expect: "Hello Alice!"
-- We get:    "Hello ${naem}!"
```

Be mindful of this!
[review-string-template](https://package.elm-lang.org/packages/emmabastas/review-string-template/latest)
together with [elm-review](https://github.com/jfmengels/elm-review)
ensures that you wont have any problems like that. It might be worth checking it out!

If you come from a language like JavaScript with first-class template literals
you might be frustrated that Elm lacks this and want to emulate it with this package.
That might not be worth the trouble! If the strings are small then normal
concatenation isn't that bad.
Elm's aproach is always to __Make things right, Not right now.__


## Alternatives

There's already two packages availible to inject values into strings.
It's up to you to decide which package to pick (and if you need one in the
first place).
But here is why I chose to make my own package instead of using one of the other
two:

* [elm-string-format](https://package.elm-lang.org/packages/jorgengranseth/elm-string-format/latest/)
is pretty nice, it has named placeholders.
The only thing it doesn't have is an `elm-review` rule removing
the risk of typos etc. Everything else is just personal preference imo!

* [elm-string-interpolate](https://package.elm-lang.org/packages/lukewestby/elm-string-interpolate/latest/) 
has no way to give the placeholders in your tamplete descriptive names.
Your template would look like this: `"Hello {0} {1}!"` instead of:
`"Hello ${firstName} ${lastName}!"`.

* Good ol' string concatenation! It's safer and more performant.
