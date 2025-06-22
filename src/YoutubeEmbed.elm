module YoutubeEmbed exposing (emailEmbed, extractVideoId, webEmbed)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.String
import Html.String.Attributes as StringAttr
import Url


extractVideoId : String -> String
extractVideoId src =
    src
        |> String.split "watch?v="
        |> List.drop 1
        |> List.head
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.head
        |> Maybe.withDefault ""


{-| Web version with iframe for normal web viewing
-}
webEmbed : String -> Html msg
webEmbed src =
    let
        videoId =
            extractVideoId src
    in
    Html.div
        [ Attr.class "w-full aspect-video bg-gray-200 shadow-lg rounded-xl overflow-hidden my-6" ]
        [ Html.iframe
            [ Attr.src ("https://www.youtube.com/embed/" ++ videoId)
            , Attr.attribute "frameborder" "0"
            , Attr.attribute "allow" "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            , Attr.attribute "allowfullscreen" "true"
            , Attr.style "width" "100%"
            , Attr.style "height" "100%"
            ]
            []
        ]


{-| Email version with thumbnail image that links to YouTube
-}
emailEmbed : String -> Html.String.Html Never
emailEmbed src =
    Html.String.a
        [ StringAttr.href src
        , StringAttr.style "display" "block"
        , StringAttr.style "width" "100%"
        , StringAttr.style "max-width" "480px"
        , StringAttr.style "margin" "0 auto"
        , StringAttr.style "border" "0"
        , StringAttr.style "text-decoration" "none"
        , StringAttr.target "_blank"
        ]
        [ Html.String.img
            [ StringAttr.alt "video preview"
            , StringAttr.src ("https://functions-js.convertkit.com/playbutton?play=%23ffffff&accent=%23f00505&thumbnailof=" ++ (src |> Url.percentEncode) ++ "&width=480&height=270&fit=contain")
            , StringAttr.width 480
            , StringAttr.height 270
            , StringAttr.style "display" "block"
            , StringAttr.style "border-radius" "4px"
            , StringAttr.style "max-width" "480px"
            , StringAttr.style "width" "100%"
            , StringAttr.style "height" "auto"
            ]
            []
        ]
