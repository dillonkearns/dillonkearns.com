module Route.Newsletters.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File
import Date
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Renderer
import MarkdownCodec
import MarkdownWebRenderer
import Newsletter
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import Signup
import Time
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


type alias Data =
    { newsletter : Newsletter.Newsletter
    , markdownBlocks : List Block.Block
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Newsletter.all
        |> BackendTask.map
            (List.map (\newsletter -> { slug = newsletter.slug }))


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    Newsletter.all
        |> BackendTask.andThen
            (\newsletters ->
                case newsletters |> List.filter (\n -> n.slug == routeParams.slug) |> List.head of
                    Just newsletter ->
                        newsletter.filePath
                            |> MarkdownCodec.withoutFrontmatter MarkdownWebRenderer.renderer
                            |> BackendTask.map
                                (\blocks ->
                                    { newsletter = newsletter
                                    , markdownBlocks = blocks
                                    }
                                )

                    Nothing ->
                        BackendTask.fail (FatalError.fromString ("Newsletter not found: " ++ routeParams.slug))
            )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Dillon Kearns"
        , image =
            { url = Pages.Url.external ""
            , alt = ""
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Newsletter from " ++ Date.toIsoString app.data.newsletter.publishAt
        , locale = Nothing
        , title = app.data.newsletter.metadata.title
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    let
        renderedResult =
            Markdown.Renderer.render MarkdownWebRenderer.renderer app.data.markdownBlocks

        content =
            case renderedResult of
                Ok rendered ->
                    rendered

                Err error ->
                    [ Html.p [ Attr.class "text-red-600" ]
                        [ Html.text ("Error rendering markdown: " ++ error) ]
                    ]
    in
    { title = app.data.newsletter.metadata.title
    , body =
        [ Html.div [ Attr.class "min-h-screen bg-gray-50" ]
            [ header
            , Html.main_ [ Attr.class "max-w-4xl mx-auto px-4 py-8" ]
                [ Html.article [ Attr.class "bg-white rounded-lg shadow-sm p-8" ]
                    [ Html.header [ Attr.class "mb-8 border-b pb-6" ]
                        [ Html.h1 [ Attr.class "text-3xl font-bold text-gray-900 mb-2" ]
                            [ Html.text app.data.newsletter.metadata.title ]
                        , Html.time
                            [ Attr.class "text-gray-600"
                            , Attr.datetime (Date.toIsoString app.data.newsletter.publishAt)
                            ]
                            [ Html.text (formatDate app.data.newsletter.publishAt) ]
                        ]
                    , Html.div [ Attr.class "prose prose-lg max-w-none" ]
                        content
                    , Html.div [ Attr.class "mt-12 pt-8 border-t" ]
                        [ Signup.view { firstName = Nothing, email = Nothing }
                        ]
                    ]
                ]
            ]
        ]
    }


formatDate : Date.Date -> String
formatDate date =
    let
        monthName =
            case Date.month date of
                Time.Jan ->
                    "January"

                Time.Feb ->
                    "February"

                Time.Mar ->
                    "March"

                Time.Apr ->
                    "April"

                Time.May ->
                    "May"

                Time.Jun ->
                    "June"

                Time.Jul ->
                    "July"

                Time.Aug ->
                    "August"

                Time.Sep ->
                    "September"

                Time.Oct ->
                    "October"

                Time.Nov ->
                    "November"

                Time.Dec ->
                    "December"
    in
    monthName ++ " " ++ String.fromInt (Date.day date) ++ ", " ++ String.fromInt (Date.year date)


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
