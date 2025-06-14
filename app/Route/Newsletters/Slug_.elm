module Route.Newsletters.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File
import Date
import FatalError exposing (FatalError)
import Time
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
import RouteBuilder exposing (App, StatelessRoute)
import Shared
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
            [ Html.main_ [ Attr.class "max-w-4xl mx-auto px-4 py-8" ]
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
                    , Html.footer [ Attr.class "mt-12 pt-8 border-t" ]
                        [ Html.div [ Attr.class "bg-blue-50 rounded-lg p-6" ]
                            [ Html.h3 [ Attr.class "text-lg font-semibold mb-2" ] 
                                [ Html.text "Get updates on upcoming shows" ]
                            , Html.p [ Attr.class "text-gray-700 mb-4" ] 
                                [ Html.text "Join my newsletter for stories from the local jazz scene and updates on where to catch live music." ]
                            , Html.a 
                                [ Attr.href "/signup"
                                , Attr.class "inline-block bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition"
                                ] 
                                [ Html.text "Subscribe to Newsletter" ]
                            ]
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
                Time.Jan -> "January"
                Time.Feb -> "February"
                Time.Mar -> "March"
                Time.Apr -> "April"
                Time.May -> "May"
                Time.Jun -> "June"
                Time.Jul -> "July"
                Time.Aug -> "August"
                Time.Sep -> "September"
                Time.Oct -> "October"
                Time.Nov -> "November"
                Time.Dec -> "December"
    in
    monthName ++ " " ++ String.fromInt (Date.day date) ++ ", " ++ String.fromInt (Date.year date)