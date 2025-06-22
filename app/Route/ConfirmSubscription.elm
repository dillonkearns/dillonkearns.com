module Route.ConfirmSubscription exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Effect
import FatalError
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Pages.Url
import PagesMsg
import Route
import RouteBuilder
import Shared
import UrlPath
import View


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    {}


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { data = data, head = head }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( {}, Effect.none )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app shared msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    {}


type alias ActionData =
    BackendTask.BackendTask FatalError.FatalError (List RouteParams)


data : BackendTask.BackendTask FatalError.FatalError Data
data =
    BackendTask.succeed {}


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summaryLarge
        { canonicalUrlOverride = Nothing
        , siteName = "Dillon Kearns - Santa Barbara Jazz Pianist"
        , image =
            { url = "https://res.cloudinary.com/dillonkearns/image/upload/w_1000,c_fill,ar_1:1,g_auto,r_max,bo_5px_solid_red,b_rgb:262c35/v1742066379/hero-color_oh0rng.jpg" |> Pages.Url.external
            , alt = "Dillon Kearns"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Check your email to confirm your subscription to jazz updates from Dillon Kearns"
        , locale = Nothing
        , title = "Confirm your subscription - Dillon Kearns"
        }
        |> Seo.website


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app shared model =
    { title = "Confirm your subscription - Dillon Kearns"
    , body =
        [ header
        , confirmationContent
        ]
    }


header : Html msg
header =
    Html.div
        [ Attr.class "md:flex md:items-center md:justify-between md:space-x-5 p-6"
        ]
        [ Route.Index
            |> Route.link
                [ Attr.class "flex items-start space-x-5"
                ]
                [ Html.div
                    [ Attr.class "shrink-0"
                    ]
                    [ Html.div
                        [ Attr.class "relative"
                        ]
                        [ Html.img
                            [ Attr.class "size-16 rounded-full object-cover"
                            , Attr.src "https://res.cloudinary.com/dillonkearns/image/upload/w_1000,c_fill,ar_1:1,g_auto,r_max,bo_5px_solid_red,b_rgb:262c35/v1742066379/hero-color_oh0rng.jpg"
                            , Attr.alt ""
                            ]
                            []
                        , Html.span
                            [ Attr.class "absolute inset-0 rounded-full shadow-inner"
                            , Attr.attribute "aria-hidden" "true"
                            ]
                            []
                        ]
                    ]
                , Html.div
                    [ Attr.class "pt-1.5"
                    ]
                    [ Html.h1
                        [ Attr.class "text-2xl font-bold text-gray-900"
                        ]
                        [ Html.text "Dillon Kearns" ]
                    , Html.p
                        [ Attr.class "text-sm font-medium text-gray-500"
                        ]
                        [ Html.text "Santa Barbara based "
                        , Html.a
                            [ Attr.class "text-gray-900"
                            ]
                            [ Html.text "Jazz Pianist" ]
                        ]
                    ]
                ]
        ]


confirmationContent : Html msg
confirmationContent =
    Html.div
        [ Attr.class "bg-indigo-700 py-16 sm:py-24 lg:py-32"
        ]
        [ Html.div
            [ Attr.class "mx-auto max-w-2xl px-6 lg:px-8"
            ]
            [ Html.div
                [ Attr.class "text-center"
                ]
                [ Html.h2
                    [ Attr.class "text-4xl font-bold tracking-tight text-white sm:text-5xl mb-8"
                    ]
                    [ Html.text "One more step" ]
                , Html.p
                    [ Attr.class "text-lg text-white/90 max-w-xl mx-auto"
                    ]
                    [ Html.text "Check your email inbox and click confirm. Then you'll be all set to receive my jazz updates!" ]
                ]
            ]
        ]
