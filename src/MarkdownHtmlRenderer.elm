module MarkdownHtmlRenderer exposing (renderer)

import Html.String as Html exposing (Html)
import Html.String.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer
import Site
import Url


renderer : Markdown.Renderer.Renderer (Html Never)
renderer =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.h2 [] children

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children
    , paragraph = Html.p []
    , strikethrough = Html.del []
    , hardLineBreak = Html.br [] []
    , blockQuote = Html.blockquote []
    , strong =
        \children -> Html.strong [] children
    , emphasis =
        \children -> Html.em [] children
    , codeSpan =
        \content -> Html.code [] [ Html.text content ]
    , link =
        \link content ->
            let
                fullUrl =
                    if link.destination |> String.startsWith "/" then
                        Site.config.canonicalUrl ++ link.destination

                    else
                        link.destination
            in
            case link.title of
                Just title ->
                    Html.a
                        [ Attr.href fullUrl
                        , Attr.title title
                        ]
                        content

                Nothing ->
                    Html.a [ Attr.href fullUrl ] content
    , image =
        \imageInfo ->
            case imageInfo.title of
                Just title ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        , Attr.title title
                        ]
                        []

                Nothing ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        ]
                        []
    , text =
        Html.text
    , unorderedList =
        \items ->
            Html.ul []
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Block.NoTask ->
                                                    Html.text ""

                                                Block.IncompleteTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked False
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    Html.li [] (checkbox :: children)
                        )
                )
    , orderedList =
        \startingIndex items ->
            Html.ol
                (if startingIndex /= 1 then
                    [ Attr.start startingIndex ]

                 else
                    []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li []
                                itemBlocks
                        )
                )
    , html =
        Markdown.Html.oneOf
            [ Markdown.Html.tag "youtube-embed"
                (\src _ ->
                    Html.a
                        [ Attr.href src
                        , Attr.style "display" "block"
                        , Attr.style "width" "100%"
                        , Attr.style "max-width" "480px"
                        , Attr.style "margin" "0 auto"
                        , Attr.style "border" "0"
                        , Attr.style "text-decoration" "none"
                        , Attr.target "_blank"
                        ]
                        [ Html.img
                            [ Attr.alt "video preview"
                            , Attr.src ("https://functions-js.convertkit.com/playbutton?play=%23ffffff&accent=%23f00505&thumbnailof=" ++ (src |> Url.percentEncode) ++ "&width=480&height=270&fit=contain")
                            , Attr.width 480
                            , Attr.height 270
                            , Attr.style "display" "block"
                            , Attr.style "border-radius" "4px"
                            , Attr.style "max-width" "480px"
                            , Attr.style "width" "100%"
                            , Attr.style "height" "auto"
                            ]
                            []
                        ]
                )
                |> Markdown.Html.withAttribute "src"
            ]
    , codeBlock =
        \{ body } ->
            Html.pre []
                [ Html.code []
                    [ Html.text body
                    ]
                ]
    , thematicBreak = Html.hr [] []
    , table = Html.table []
    , tableHeader = Html.thead []
    , tableBody = Html.tbody []
    , tableRow = Html.tr []
    , tableHeaderCell =
        \maybeAlignment ->
            let
                attrs =
                    maybeAlignment
                        |> Maybe.map
                            (\alignment ->
                                case alignment of
                                    Block.AlignLeft ->
                                        "left"

                                    Block.AlignCenter ->
                                        "center"

                                    Block.AlignRight ->
                                        "right"
                            )
                        |> Maybe.map Attr.align
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
            in
            Html.th attrs
    , tableCell =
        \maybeAlignment ->
            let
                attrs =
                    maybeAlignment
                        |> Maybe.map
                            (\alignment ->
                                case alignment of
                                    Block.AlignLeft ->
                                        "left"

                                    Block.AlignCenter ->
                                        "center"

                                    Block.AlignRight ->
                                        "right"
                            )
                        |> Maybe.map Attr.align
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
            in
            Html.td attrs
    }
