module Route.Newsletters.Preview.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File
import Date
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Html.String
import Json.Encode
import Markdown.Block as Block
import Markdown.Renderer
import MarkdownCodec
import MarkdownHtmlRenderer
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
                            |> MarkdownCodec.withoutFrontmatter MarkdownHtmlRenderer.renderer
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
        , description = "Newsletter preview"
        , locale = Nothing
        , title = app.data.newsletter.metadata.title ++ " - Preview"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    let
        renderedResult =
            Markdown.Renderer.render MarkdownHtmlRenderer.renderer app.data.markdownBlocks

        htmlContent =
            case renderedResult of
                Ok rendered ->
                    rendered
                        |> MarkdownHtmlRenderer.renderEmailTemplate
                        |> Html.String.toHtml
                        |> Html.map never

                Err error ->
                    Html.text ("Error rendering markdown: " ++ error)
    in
    { title = app.data.newsletter.metadata.title ++ " - Preview"
    , body =
        [ Html.div
            [ Attr.style "max-width" "600px"
            , Attr.style "margin" "0 auto"
            , Attr.style "padding" "20px"
            , Attr.style "font-family" "system-ui, -apple-system, sans-serif"
            ]
            [ Html.h1 [] [ Html.text "Newsletter Preview" ]
            , Html.div
                [ Attr.style "background" "#f5f5f5"
                , Attr.style "padding" "15px"
                , Attr.style "border-radius" "8px"
                , Attr.style "margin-bottom" "20px"
                , Attr.style "font-size" "14px"
                ]
                [ Html.p [ Attr.style "margin" "0 0 10px 0" ] 
                    [ Html.strong [] [ Html.text "Title: " ]
                    , Html.text app.data.newsletter.metadata.title 
                    ]
                , Html.p [ Attr.style "margin" "0 0 10px 0" ] 
                    [ Html.strong [] [ Html.text "Publish Date: " ]
                    , Html.text (Date.toIsoString app.data.newsletter.publishAt) 
                    ]
                , Html.p [ Attr.style "margin" "0" ] 
                    [ Html.strong [] [ Html.text "RSS Feed: " ]
                    , Html.a 
                        [ Attr.href "/newsletters/feed.xml"
                        , Attr.target "_blank"
                        , Attr.style "color" "#0066cc"
                        ] 
                        [ Html.text "/newsletters/feed.xml" ] 
                    ]
                ]
            , Html.div
                [ Attr.style "border" "1px solid #ddd"
                , Attr.style "padding" "0"
                , Attr.style "background" "white"
                , Attr.style "border-radius" "8px"
                , Attr.style "box-shadow" "0 2px 4px rgba(0,0,0,0.1)"
                , Attr.style "overflow" "hidden"
                ]
                [ htmlContent ]
            , Html.div
                [ Attr.style "margin-top" "20px"
                , Attr.style "padding" "15px"
                , Attr.style "background" "#e8f4fd"
                , Attr.style "border-radius" "8px"
                , Attr.style "font-size" "14px"
                , Attr.style "color" "#0066cc"
                ]
                [ Html.p [ Attr.style "margin" "0" ] 
                    [ Html.strong [] [ Html.text "Preview Note: " ]
                    , Html.text "This shows how your newsletter will appear in Kit.com emails. YouTube embeds are displayed as clickable thumbnail images that link to the video."
                    ]
                ]
            ]
        ]
    }
