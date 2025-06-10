module Signup exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : Html msg
view =
    Html.div
        [ Attr.class "bg-indigo-700 py-16 sm:py-24 lg:py-32"
        ]
        [ Html.div
            [ Attr.class "mx-auto grid max-w-7xl grid-cols-1 gap-10 px-6 lg:grid-cols-12 lg:gap-8 lg:px-8"
            ]
            [ Html.h2
                [ Attr.class "max-w-xl text-3xl font-semibold tracking-tight text-white sm:text-4xl lg:col-span-7"
                ]
                [ Html.text "Get updates on my upcoming Santa Barbara shows and stories from the local music scene." ]
            , Html.form
                [ Attr.action "https://app.kit.com/forms/8167571/subscriptions"
                , Attr.method "POST"
                , Attr.class "w-full max-w-md lg:col-span-5 lg:pt-2 space-y-4"
                ]
                [ Html.div
                    [ Attr.class "flex flex-col gap-y-4"
                    ]
                    [ Html.div
                        [ Attr.class "flex gap-x-4"
                        ]
                        [ Html.label
                            [ Attr.for "first_name"
                            , Attr.class "sr-only"
                            ]
                            [ Html.text "First Name" ]
                        , Html.input
                            [ Attr.type_ "text"
                            , Attr.name "fields[first_name]"
                            , Attr.id "first_name"
                            , Attr.placeholder "First name"
                            , Attr.class "min-w-0 flex-auto rounded-md bg-white/10 px-3.5 py-2 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-white/75 focus:outline-2 focus:-outline-offset-2 focus:outline-white sm:text-sm/6"
                            ]
                            []
                        , Html.label
                            [ Attr.for "email_address"
                            , Attr.class "sr-only"
                            ]
                            [ Html.text "Email address" ]
                        , Html.input
                            [ Attr.type_ "email"
                            , Attr.name "email_address"
                            , Attr.id "email_address"
                            , Attr.required True
                            , Attr.attribute "autocomplete" "email"
                            , Attr.placeholder "Your email"
                            , Attr.class "min-w-0 flex-auto rounded-md bg-white/10 px-3.5 py-2 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-white/75 focus:outline-2 focus:-outline-offset-2 focus:outline-white sm:text-sm/6"
                            ]
                            []
                        , Html.button
                            [ Attr.type_ "submit"
                            , Attr.class "flex-none rounded-md bg-white px-3.5 py-2.5 text-sm font-semibold text-indigo-600 shadow-xs hover:bg-indigo-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white cursor-pointer"
                            ]
                            [ Html.text "Sign Up" ]
                        ]
                    ]
                , Html.p
                    [ Attr.class "mt-4 text-sm/6 text-gray-300"
                    ]
                    [ Html.text "Hit unsubscribe any time! I only send occasionally updates about my music and upcoming shows."
                    ]
                ]
            ]
        ]
