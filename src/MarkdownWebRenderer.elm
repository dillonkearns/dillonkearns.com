module MarkdownWebRenderer exposing (renderer)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer
import Site
import Url
import YoutubeEmbed


renderer : Markdown.Renderer.Renderer (Html msg)
renderer =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [ Attr.class "text-4xl font-bold mb-4" ] children

                Block.H2 ->
                    Html.h2 [ Attr.class "text-2xl font-bold mt-8 mb-4" ] children

                Block.H3 ->
                    Html.h3 [ Attr.class "text-xl font-semibold mt-6 mb-3" ] children

                Block.H4 ->
                    Html.h4 [ Attr.class "text-lg font-semibold mt-4 mb-2" ] children

                Block.H5 ->
                    Html.h5 [ Attr.class "font-semibold mt-3 mb-2" ] children

                Block.H6 ->
                    Html.h6 [ Attr.class "font-semibold mt-3 mb-2" ] children
    , paragraph = Html.p [ Attr.class "mb-4 leading-relaxed" ]
    , strikethrough = Html.del []
    , hardLineBreak = Html.br [] []
    , blockQuote = Html.blockquote [ Attr.class "border-l-4 border-gray-300 pl-4 italic my-4" ]
    , strong = \children -> Html.strong [ Attr.class "font-semibold" ] children
    , emphasis = \children -> Html.em [ Attr.class "italic" ] children
    , codeSpan = \content -> Html.code [ Attr.class "bg-gray-100 px-1 py-0.5 rounded text-sm" ] [ Html.text content ]
    , link =
        \link content ->
            case link.title of
                Just title ->
                    Html.a
                        [ Attr.href link.destination
                        , Attr.title title
                        , Attr.class "text-blue-600 hover:text-blue-800 underline"
                        ]
                        content

                Nothing ->
                    Html.a 
                        [ Attr.href link.destination
                        , Attr.class "text-blue-600 hover:text-blue-800 underline"
                        ] 
                        content
    , image =
        \imageInfo ->
            case imageInfo.title of
                Just title ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        , Attr.title title
                        , Attr.class "max-w-full h-auto rounded-lg my-4"
                        ]
                        []

                Nothing ->
                    Html.img
                        [ Attr.src imageInfo.src
                        , Attr.alt imageInfo.alt
                        , Attr.class "max-w-full h-auto rounded-lg my-4"
                        ]
                        []
    , text = Html.text
    , unorderedList =
        \items ->
            Html.ul [ Attr.class "list-disc pl-6 mb-4 space-y-1" ]
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
                                                        , Attr.class "mr-2"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        , Attr.class "mr-2"
                                                        ]
                                                        []
                                    in
                                    Html.li [] (checkbox :: children)
                        )
                )
    , orderedList =
        \startingIndex items ->
            Html.ol
                ([ Attr.class "list-decimal pl-6 mb-4 space-y-1" ]
                    ++ (if startingIndex /= 1 then
                            [ Attr.start startingIndex ]

                        else
                            []
                       )
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
                (\src _ -> YoutubeEmbed.webEmbed src)
                |> Markdown.Html.withAttribute "src"
            ]
    , codeBlock =
        \{ body, language } ->
            Html.pre [ Attr.class "bg-gray-100 p-4 rounded-lg overflow-x-auto mb-4" ]
                [ Html.code [ Attr.class "text-sm" ]
                    [ Html.text body
                    ]
                ]
    , thematicBreak = Html.hr [ Attr.class "my-8 border-gray-300" ] []
    , table = Html.table [ Attr.class "min-w-full divide-y divide-gray-200 mb-4" ] 
    , tableHeader = Html.thead [ Attr.class "bg-gray-50" ]
    , tableBody = Html.tbody [ Attr.class "bg-white divide-y divide-gray-200" ]
    , tableRow = Html.tr []
    , tableHeaderCell =
        \maybeAlignment ->
            Html.th 
                [ Attr.class "px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider" ]
    , tableCell =
        \maybeAlignment ->
            Html.td 
                [ Attr.class "px-6 py-4 whitespace-nowrap text-sm text-gray-900" ]
    }