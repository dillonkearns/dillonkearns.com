module MarkdownHtmlRenderer exposing (renderer, renderEmailTemplate, rssRenderer)

import Html.String as Html exposing (Html)
import Html.String.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer
import Site
import Url
import YoutubeEmbed


renderer : Markdown.Renderer.Renderer (Html Never)
renderer =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.div [ Attr.style "margin" "0", Attr.style "padding" "24px 0 16px 0" ]
                        [ Html.h2 
                            [ Attr.style "font-family" "-apple-system, BlinkMacSystemFont, sans-serif"
                            , Attr.style "font-size" "24px"
                            , Attr.style "color" "rgb(0, 0, 0)"
                            , Attr.style "font-weight" "800"
                            , Attr.style "line-height" "1"
                            , Attr.style "margin" "0"
                            ] 
                            children
                        ]

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children
    , paragraph = \children ->
        Html.div [ Attr.style "margin" "0", Attr.style "padding" "0 0 16px 0" ]
            [ Html.p 
                [ Attr.style "font-family" "-apple-system, BlinkMacSystemFont, sans-serif"
                , Attr.style "font-size" "18px"
                , Attr.style "color" "#353535"
                , Attr.style "font-weight" "400"
                , Attr.style "line-height" "1.5"
                , Attr.style "margin" "0"
                ]
                children
            ]
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
                        , Attr.class "ck-link"
                        , Attr.style "color" "#3da9f9"
                        , Attr.target "_blank"
                        , Attr.rel "noopener noreferrer"
                        ]
                        content

                Nothing ->
                    Html.a 
                        [ Attr.href fullUrl
                        , Attr.class "ck-link"
                        , Attr.style "color" "#3da9f9"
                        , Attr.target "_blank"
                        , Attr.rel "noopener noreferrer"
                        ] 
                        content
    , image =
        \imageInfo ->
            Html.table
                [ Attr.attribute "width" "100%"
                , Attr.attribute "border" "0"
                , Attr.attribute "cellspacing" "0"
                , Attr.attribute "cellpadding" "0"
                , Attr.style "text-align" "center"
                , Attr.style "table-layout" "fixed"
                , Attr.style "float" "none"
                ]
                [ Html.tbody []
                    [ Html.tr []
                        [ Html.td [ Attr.align "center" ]
                            [ Html.node "figure"
                                [ Attr.style "margin-top" "12px"
                                , Attr.style "margin-bottom" "12px"
                                , Attr.style "margin-left" "0"
                                , Attr.style "margin-right" "0"
                                , Attr.style "max-width" "800px"
                                , Attr.style "width" "100%"
                                ]
                                [ Html.div [ Attr.style "display" "block" ]
                                    [ Html.img
                                        ([ Attr.src imageInfo.src
                                        , Attr.alt imageInfo.alt
                                        , Attr.width 800
                                        , Attr.attribute "height" "auto"
                                        , Attr.style "display" "block"
                                        , Attr.style "border-radius" "4px 4px 4px 4px"
                                        , Attr.style "width" "800px"
                                        , Attr.style "height" "auto"
                                        , Attr.style "object-fit" "contain"
                                        ] ++ (case imageInfo.title of
                                            Just title -> [ Attr.title title ]
                                            Nothing -> []
                                        ))
                                        []
                                    ]
                                , Html.node "figcaption"
                                    [ Attr.style "text-align" "center"
                                    , Attr.style "display" "block"
                                    ]
                                    [ Html.text imageInfo.alt ]
                                ]
                            ]
                        ]
                    ]
                ]
    , text =
        Html.text
    , unorderedList =
        \items ->
            Html.ul 
                [ Attr.style "font-family" "-apple-system,BlinkMacSystemFont,sans-serif"
                , Attr.style "font-size" "18px"
                , Attr.style "color" "#353535"
                , Attr.style "font-weight" "400"
                , Attr.style "line-height" "1.5"
                , Attr.style "text-align" "left"
                ]
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
                                    Html.li [] 
                                        (checkbox :: 
                                            [ Html.span [] children ]
                                        )
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
                (\src _ -> YoutubeEmbed.emailEmbed src)
                |> Markdown.Html.withAttribute "src"
            , Markdown.Html.tag "email-button"
                (\href text _ ->
                    Html.table [ Attr.attribute "width" "100%" ]
                        [ Html.tbody []
                            [ Html.tr []
                                [ Html.td [ Attr.align "center" ]
                                    [ Html.a
                                        [ Attr.class "email-button"
                                        , Attr.rel "noopener noreferrer"
                                        , Attr.style "background-color" "#2c2c2c"
                                        , Attr.style "color" "#ffffff"
                                        , Attr.style "border-radius" "0px"
                                        , Attr.style "font-family" "-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Oxygen-Sans,Ubuntu,Cantarell,'Helvetica Neue',sans-serif"
                                        , Attr.style "border-color" "#2c2c2c"
                                        , Attr.style "background-color" "#2c2c2c"
                                        , Attr.style "box-sizing" "border-box"
                                        , Attr.style "border-style" "solid"
                                        , Attr.style "color" "#ffffff"
                                        , Attr.style "display" "inline-block"
                                        , Attr.style "text-align" "center"
                                        , Attr.style "text-decoration" "none"
                                        , Attr.style "padding" "12px 20px"
                                        , Attr.style "margin-top" "8px"
                                        , Attr.style "margin-bottom" "8px"
                                        , Attr.style "font-size" "16px"
                                        , Attr.style "border-radius" "4px 4px 4px 4px"
                                        , Attr.href href
                                        ]
                                        [ Html.text text ]
                                    ]
                                ]
                            ]
                        ]
                )
                |> Markdown.Html.withAttribute "href"
                |> Markdown.Html.withAttribute "text"
            ]
    , codeBlock =
        \{ body } ->
            Html.pre []
                [ Html.code []
                    [ Html.text body
                    ]
                ]
    , thematicBreak = Html.hr [ Attr.style "margin-top" "48px", Attr.style "margin-bottom" "48px" ] []
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


renderEmailTemplate : List (Html Never) -> Html Never
renderEmailTemplate content =
    Html.div [ Attr.style "background-color" "#ffffff" ]
        [ Html.table
            [ Attr.attribute "role" "presentation"
            , Attr.attribute "cellpadding" "0"
            , Attr.attribute "cellspacing" "0"
            , Attr.style "background" "#f3f3f3!important"
            , Attr.style "width" "100%"
            , Attr.attribute "bgcolor" "#ffffff"
            ]
            [ Html.tbody []
                [ Html.tr []
                    [ Html.td []
                        [ Html.div
                            [ Attr.style "padding-top" "0"
                            , Attr.style "padding-left" "0"
                            , Attr.style "padding-bottom" "30px"
                            , Attr.style "padding-right" "0"
                            , Attr.style "margin" "0 auto"
                            , Attr.style "max-width" "100%"
                            ]
                            [ Html.table
                                [ Attr.attribute "cellpadding" "0"
                                , Attr.attribute "cellspacing" "0"
                                , Attr.attribute "bgcolor" "#f3f3f3"
                                , Attr.style "width" "100%"
                                , Attr.style "margin" "0 auto"
                                , Attr.style "background-color" "#f3f3f3"
                                ]
                                [ Html.tbody []
                                    [ Html.tr []
                                        [ Html.td []
                                            [ Html.div [ Attr.style "margin" "0px auto 0px auto" ]
                                                [ Html.node "center" []
                                                    [ Html.table
                                                        [ Attr.attribute "cellpadding" "0"
                                                        , Attr.attribute "cellspacing" "0"
                                                        , Attr.style "width" "100%"
                                                        , Attr.style "margin" "0 auto"
                                                        , Attr.style "max-width" "100%"
                                                        ]
                                                        [ Html.tbody []
                                                            [ Html.tr []
                                                                [ Html.td [] []
                                                                , Html.td
                                                                    [ Attr.width 100
                                                                    , Attr.style "width" "100%"
                                                                    , Attr.style "background-color" "#ffffff"
                                                                    , Attr.style "border-radius" "0px"
                                                                    , Attr.style "box-sizing" "border-box"
                                                                    , Attr.attribute "bgcolor" "#FFFFFF"
                                                                    ]
                                                                    [ Html.div [ Attr.style "padding" "40px 0px 40px 0px" ]
                                                                        [ Html.div
                                                                            [ Attr.style "margin-left" "auto"
                                                                            , Attr.style "margin-right" "auto"
                                                                            , Attr.style "max-width" "640px"
                                                                            ]
                                                                            content
                                                                        ]
                                                                    ]
                                                                , Html.td [] []
                                                                ]
                                                            ]
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


rssRenderer : Markdown.Renderer.Renderer (Html Never)
rssRenderer =
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
    , strong = Html.strong []
    , emphasis = Html.em []
    , codeSpan = \content -> Html.code [] [ Html.text content ]
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
    , text = Html.text
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
            Html.ol []
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li [] itemBlocks
                        )
                )
    , html =
        Markdown.Html.oneOf
            [ Markdown.Html.tag "youtube-embed"
                (\src _ -> YoutubeEmbed.emailEmbed src)
                |> Markdown.Html.withAttribute "src"
            ]
    , codeBlock =
        \{ body, language } ->
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
