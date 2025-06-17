module Api exposing (routes)

import ApiRoute exposing (ApiRoute)
import BackendTask exposing (BackendTask)
import BackendTask.File
import Date
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.String
import MarkdownCodec
import MarkdownHtmlRenderer
import Markdown.Renderer
import Newsletter
import Pages
import Pages.Manifest as Manifest
import Route exposing (Route)
import Rss
import Site


routes :
    BackendTask FatalError (List Route)
    -> (Maybe { indent : Int, newLines : Bool } -> Html Never -> String)
    -> List (ApiRoute ApiRoute.Response)
routes getStaticRoutes htmlToString =
    [ ApiRoute.succeed
        (newsletterFeedItems
            |> BackendTask.map
                (\feedItems ->
                    Rss.generate
                        { title = "Dillon Kearns Newsletter"
                        , description = "Get updates on my upcoming shows, video highlights of our music, and stories from the local jazz scene."
                        , url = Site.config.canonicalUrl ++ "/newsletters"
                        , lastBuildTime = Pages.builtAt
                        , generator = Just "elm-pages"
                        , items = feedItems
                        , siteUrl = Site.config.canonicalUrl
                        }
                )
        )
        |> ApiRoute.literal "newsletters"
        |> ApiRoute.slash
        |> ApiRoute.literal "feed.xml"
        |> ApiRoute.single
    ]


newsletterFeedItems : BackendTask FatalError (List Rss.Item)
newsletterFeedItems =
    Newsletter.all
        |> BackendTask.andThen
            (\newsletters ->
                newsletters
                    |> List.map newsletterToFeedItem
                    |> BackendTask.combine
            )


newsletterToFeedItem : Newsletter.Newsletter -> BackendTask FatalError Rss.Item
newsletterToFeedItem newsletter =
    newsletter.filePath
        |> BackendTask.File.bodyWithoutFrontmatter
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\markdownContent ->
                newsletter.filePath
                    |> MarkdownCodec.withoutFrontmatter MarkdownHtmlRenderer.renderer
                    |> BackendTask.andThen
                        (\blocks ->
                            case Markdown.Renderer.render MarkdownHtmlRenderer.renderer blocks of
                                Ok renderedHtml ->
                                    let
                                        -- Just the content HTML without email template wrapper
                                        bodyHtml =
                                            renderedHtml
                                                |> List.map (Html.String.toString 0)
                                                |> String.join ""
                                        
                                        -- Extract plain text from markdown
                                        plainText =
                                            markdownContent
                                                |> String.lines
                                                |> List.map String.trim
                                                |> List.filter (not << String.isEmpty)
                                                |> String.join " "
                                    in
                                    BackendTask.succeed
                                        { title = newsletter.metadata.title
                                        , description = newsletter.metadata.title
                                        , url = "/newsletters/" ++ newsletter.slug
                                        , categories = []
                                        , author = "Dillon Kearns"
                                        , pubDate = Rss.Date newsletter.publishAt
                                        , content = Just plainText
                                        , contentEncoded = Just bodyHtml
                                        , enclosure = Nothing
                                        }

                                Err error ->
                                    BackendTask.fail (FatalError.fromString ("Markdown rendering error: " ++ error))
                        )
            )


manifest : Manifest.Config
manifest =
    Manifest.init
        { name = "Dillon Kearns"
        , description = "Description"
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }
