module Signup exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr


view : { firstName : Maybe String, email : Maybe String } -> Html msg
view params =
    Html.div
        [ Attr.class "bg-indigo-700 py-16 sm:py-24 lg:py-32"
        ]
        [ Html.div
            [ Attr.class "mx-auto max-w-2xl px-6 lg:px-8"
            ]
            [ Html.div
                [ Attr.class "text-center mb-8"
                ]
                [ Html.h1
                    [ Attr.class "text-4xl font-bold tracking-tight text-white sm:text-5xl mb-4"
                    ]
                    [ Html.text "Stay Connected" ]
                , Html.p
                    [ Attr.class "text-lg text-white/90 max-w-xl mx-auto"
                    ]
                    [ Html.text "Get updates on my upcoming shows and stories from the local jazz scene." ]
                ]
            , Html.form
                [ Attr.action "https://app.kit.com/forms/8167571/subscriptions"
                , Attr.method "POST"
                , Attr.class "max-w-md mx-auto"
                ]
                [ Html.div
                    [ Attr.class "space-y-4"
                    ]
                    [ Html.div
                        []
                        [ Html.label
                            [ Attr.for "first_name"
                            , Attr.class "sr-only"
                            ]
                            [ Html.text "First Name" ]
                        , Html.input
                            ([ Attr.type_ "text"
                             , Attr.name "fields[first_name]"
                             , Attr.id "first_name"
                             , Attr.placeholder "First name"
                             , Attr.class "w-full rounded-md bg-white/10 px-3.5 py-3 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-white/75 focus:outline-2 focus:-outline-offset-2 focus:outline-white sm:text-sm/6"
                             ]
                                ++ (case params.firstName of
                                        Just firstName ->
                                            [ Attr.value firstName ]

                                        Nothing ->
                                            []
                                   )
                            )
                            []
                        ]
                    , Html.div
                        []
                        [ Html.label
                            [ Attr.for "email_address"
                            , Attr.class "sr-only"
                            ]
                            [ Html.text "Email address" ]
                        , Html.input
                            ([ Attr.type_ "email"
                             , Attr.name "email_address"
                             , Attr.id "email_address"
                             , Attr.required True
                             , Attr.attribute "autocomplete" "email"
                             , Attr.placeholder "Your email"
                             , Attr.class "w-full rounded-md bg-white/10 px-3.5 py-3 text-base text-white outline-1 -outline-offset-1 outline-white/10 placeholder:text-white/75 focus:outline-2 focus:-outline-offset-2 focus:outline-white sm:text-sm/6"
                             ]
                                ++ (case params.email of
                                        Just email ->
                                            [ Attr.value email ]

                                        Nothing ->
                                            []
                                   )
                            )
                            []
                        ]
                    , Html.button
                        [ Attr.type_ "submit"
                        , Attr.class "w-full rounded-md bg-white px-3.5 py-3 text-sm font-semibold text-indigo-600 shadow-xs hover:bg-indigo-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white cursor-pointer"
                        ]
                        [ Html.text "Sign Up" ]
                    ]
                , Html.p
                    [ Attr.class "mt-6 text-sm text-center text-gray-300"
                    ]
                    [ Html.text "Hit unsubscribe any time. I only send occasional updates about my music and upcoming shows."
                    ]
                ]
            ]
        ]
