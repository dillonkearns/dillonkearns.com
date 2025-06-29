module Route.Today exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import BackendTask.Env
import BackendTask.Http
import DateFormat
import Effect
import Event
import FatalError
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Decode exposing (Decoder)
import Pages.Url
import PagesMsg
import Route
import RouteBuilder
import Shared
import Signup
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Task
import Time
import UrlPath
import View


type alias Model =
    { zone : Time.Zone }


type Msg
    = GotTimezone Time.Zone


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
    ( { zone = Time.utc }
    , Effect.fromCmd (Time.here |> Task.perform GotTimezone)
    )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app shared msg model =
    case msg of
        GotTimezone zone ->
            ( { model | zone = zone }, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    { todayEvent : Maybe Event.Event
    , band : Maybe Band
    , musicians : List Musician
    }


type alias ActionData =
    BackendTask.BackendTask FatalError.FatalError (List RouteParams)


data : BackendTask.BackendTask FatalError.FatalError Data
data =
    Event.getEvents
        |> BackendTask.andThen
            (\events ->
                let
                    todayEvent =
                        findTodayEvent events
                in
                case todayEvent of
                    Just event ->
                        let
                            bandTask =
                                case event.bandId of
                                    Just bandId ->
                                        getBand bandId
                                            |> BackendTask.map Just

                                    Nothing ->
                                        BackendTask.succeed Nothing

                            musiciansTask =
                                case event.musicianIds of
                                    [] ->
                                        BackendTask.succeed []

                                    ids ->
                                        getMusicians ids
                        in
                        BackendTask.map2
                            (\band musicians ->
                                { todayEvent = todayEvent
                                , band = band
                                , musicians = musicians
                                }
                            )
                            bandTask
                            musiciansTask

                    Nothing ->
                        BackendTask.succeed
                            { todayEvent = Nothing
                            , band = Nothing
                            , musicians = []
                            }
            )


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    Seo.summaryLarge
        { canonicalUrlOverride = Nothing
        , siteName = "Today's Lineup"
        , image =
            { url = "https://res.cloudinary.com/dillonkearns/image/upload/w_1000,c_fill,ar_1:1,g_auto,r_max,bo_5px_solid_red,b_rgb:262c35/v1742066379/hero-color_oh0rng.jpg" |> Pages.Url.external
            , alt = "Today's Lineup"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Today's Jazz Performance Lineup"
        , locale = Nothing
        , title = "Today's Lineup - Dillon Kearns Jazz"
        }
        |> Seo.website


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app shared model =
    { title = "Today's Lineup"
    , body =
        case app.data.todayEvent of
            Just event ->
                [ viewLineup model.zone event app.data.band app.data.musicians
                , Signup.view { firstName = Nothing, email = Nothing }
                ]

            Nothing ->
                [ Html.div
                    [ Attr.class "bg-white min-h-screen py-12 px-4 text-center" ]
                    [ Html.h1
                        [ Attr.class "text-3xl font-bold text-gray-900" ]
                        [ Html.text "No event scheduled for today" ]
                    ]
                , Signup.view { firstName = Nothing, email = Nothing }
                ]
    }


type alias Musician =
    { name : String
    , instrument : String
    , socialLinks : List SocialLink
    , headshot : Maybe String
    }


type alias Band =
    { name : String
    , socialLinks : List SocialLink
    }


type alias SocialLink =
    { platform : SocialPlatform
    , url : String
    }


type SocialPlatform
    = Instagram
    | Website
    | Spotify
    | YouTube
    | Facebook


viewLineup : Time.Zone -> Event.Event -> Maybe Band -> List Musician -> Html msg
viewLineup zone event maybeBand musicians =
    Html.div
        [ Attr.class "bg-white min-h-screen py-12 px-4 sm:px-6 lg:px-8"
        ]
        [ Html.div
            [ Attr.class "max-w-4xl mx-auto"
            ]
            [ Html.h1
                [ Attr.class "text-5xl font-bold text-center text-gray-900 mb-8"
                ]
                [ Html.text "Today's Lineup" ]
            , Html.p
                [ Attr.class "text-center text-gray-600 mb-2 text-xl font-medium"
                ]
                [ Html.text event.name ]
            , Html.p
                [ Attr.class "text-center text-gray-500 mb-16 text-lg"
                ]
                [ Html.text (formatEventTime zone event.dateTimeStart ++ " • " ++ event.location.name) ]
            , case maybeBand of
                Just band ->
                    Html.div []
                        [ Html.h2
                            [ Attr.class "text-3xl font-bold text-gray-900 mb-8"
                            ]
                            [ Html.text "Featured Band" ]
                        , viewBand band
                        , Html.h2
                            [ Attr.class "text-3xl font-bold text-gray-900 mt-16 mb-8"
                            ]
                            [ Html.text "Musicians Playing the Gig" ]
                        , Html.div
                            [ Attr.class "space-y-8"
                            ]
                            (List.map viewMusician musicians)
                        ]

                Nothing ->
                    Html.div []
                        [ Html.h2
                            [ Attr.class "text-3xl font-bold text-gray-900 mb-8"
                            ]
                            [ Html.text "Musicians Playing the Gig" ]
                        , Html.div
                            [ Attr.class "space-y-8"
                            ]
                            (List.map viewMusician musicians)
                        ]
            ]
        ]


formatEventTime : Time.Zone -> Time.Posix -> String
formatEventTime zone time =
    DateFormat.format
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text ", "
        , DateFormat.monthNameAbbreviated
        , DateFormat.text " "
        , DateFormat.dayOfMonthNumber
        , DateFormat.text " at "
        , DateFormat.hourFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text " "
        , DateFormat.amPmLowercase
        ]
        zone
        time


viewBand : Band -> Html msg
viewBand band =
    Html.div
        [ Attr.class "bg-gray-50 rounded-2xl p-8 shadow-sm border border-gray-200"
        ]
        [ Html.div
            [ Attr.class "flex items-center gap-6 mb-6"
            ]
            [ Html.div
                [ Attr.class "w-20 h-20 rounded-full bg-gray-300 flex items-center justify-center flex-shrink-0"
                ]
                [ Html.span
                    [ Attr.class "text-gray-600 text-2xl font-bold"
                    ]
                    [ Html.text (String.left 1 band.name) ]
                ]
            , Html.div []
                [ Html.h3
                    [ Attr.class "text-3xl font-bold text-gray-900 mb-1"
                    ]
                    [ Html.text band.name ]
                , Html.p
                    [ Attr.class "text-gray-600 text-lg"
                    ]
                    [ Html.text "Band" ]
                ]
            ]
        , Html.div
            [ Attr.class "flex gap-x-3"
            ]
            (List.map (viewSocialLink band.name) band.socialLinks)
        ]


viewMusician : Musician -> Html msg
viewMusician musician =
    Html.div
        [ Attr.class "bg-white border-b border-gray-200 last:border-b-0 pb-8 last:pb-0"
        ]
        [ Html.div
            [ Attr.class "flex items-center gap-6 mb-4"
            ]
            [ case musician.headshot of
                Just headshotUrl ->
                    Html.img
                        [ Attr.src headshotUrl
                        , Attr.alt (musician.name ++ " headshot")
                        , Attr.class "w-24 h-24 rounded-full object-cover flex-shrink-0"
                        ]
                        []

                Nothing ->
                    Html.div
                        [ Attr.class "w-24 h-24 rounded-full bg-gray-300 flex items-center justify-center flex-shrink-0"
                        ]
                        [ Html.span
                            [ Attr.class "text-gray-600 text-2xl font-bold"
                            ]
                            [ Html.text (String.left 1 musician.name) ]
                        ]
            , Html.div [ Attr.class "flex-1" ]
                [ Html.h3
                    [ Attr.class "text-2xl font-bold text-gray-900 mb-1"
                    ]
                    [ Html.text musician.name ]
                , Html.p
                    [ Attr.class "text-gray-600 text-lg mb-3"
                    ]
                    [ Html.text musician.instrument ]
                , Html.div
                    [ Attr.class "flex gap-x-3"
                    ]
                    (List.map (viewSocialLink musician.name) musician.socialLinks)
                ]
            ]
        ]


viewSocialLink : String -> SocialLink -> Html msg
viewSocialLink musicianName link =
    Html.a
        [ Attr.href link.url
        , Attr.target "_blank"
        , Attr.rel "noopener noreferrer"
        , Attr.class "w-10 h-10 rounded-lg bg-purple-500 hover:bg-purple-600 flex items-center justify-center text-white transition-colors"
        ]
        [ Html.span
            [ Attr.class "sr-only"
            ]
            [ Html.text (musicianName ++ " on " ++ socialPlatformToString link.platform) ]
        , socialIcon link.platform
        ]


socialPlatformToString : SocialPlatform -> String
socialPlatformToString platform =
    case platform of
        Instagram ->
            "Instagram"

        Website ->
            "Website"

        Spotify ->
            "Spotify"

        YouTube ->
            "YouTube"

        Facebook ->
            "Facebook"


socialIcon : SocialPlatform -> Html msg
socialIcon platform =
    case platform of
        Instagram ->
            Svg.svg
                [ SvgAttr.class "w-5 h-5"
                , SvgAttr.fill "currentColor"
                , SvgAttr.viewBox "0 0 24 24"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Svg.path
                    [ SvgAttr.fillRule "evenodd"
                    , SvgAttr.d "M12.315 2c2.43 0 2.784.013 3.808.06 1.064.049 1.791.218 2.427.465a4.902 4.902 0 011.772 1.153 4.902 4.902 0 011.153 1.772c.247.636.416 1.363.465 2.427.048 1.067.06 1.407.06 4.123v.08c0 2.643-.012 2.987-.06 4.043-.049 1.064-.218 1.791-.465 2.427a4.902 4.902 0 01-1.153 1.772 4.902 4.902 0 01-1.772 1.153c-.636.247-1.363.416-2.427.465-1.067.048-1.407.06-4.123.06h-.08c-2.643 0-2.987-.012-4.043-.06-1.064-.049-1.791-.218-2.427-.465a4.902 4.902 0 01-1.772-1.153 4.902 4.902 0 01-1.153-1.772c-.247-.636-.416-1.363-.465-2.427-.047-1.024-.06-1.379-.06-3.808v-.63c0-2.43.013-2.784.06-3.808.049-1.064.218-1.791.465-2.427a4.902 4.902 0 011.153-1.772A4.902 4.902 0 015.45 2.525c.636-.247 1.363-.416 2.427-.465C8.901 2.013 9.256 2 11.685 2h.63zm-.081 1.802h-.468c-2.456 0-2.784.011-3.807.058-.975.045-1.504.207-1.857.344-.467.182-.8.398-1.15.748-.35.35-.566.683-.748 1.15-.137.353-.3.882-.344 1.857-.047 1.023-.058 1.351-.058 3.807v.468c0 2.456.011 2.784.058 3.807.045.975.207 1.504.344 1.857.182.466.399.8.748 1.15.35.35.683.566 1.15.748.353.137.882.3 1.857.344 1.054.048 1.37.058 4.041.058h.08c2.597 0 2.917-.01 3.96-.058.976-.045 1.505-.207 1.858-.344.466-.182.8-.398 1.15-.748.35-.35.566-.683.748-1.15.137-.353.3-.882.344-1.857.048-1.055.058-1.37.058-4.041v-.08c0-2.597-.01-2.917-.058-3.96-.045-.976-.207-1.505-.344-1.858a3.097 3.097 0 00-.748-1.15 3.098 3.098 0 00-1.15-.748c-.353-.137-.882-.3-1.857-.344-1.023-.047-1.351-.058-3.807-.058zM12 6.865a5.135 5.135 0 110 10.27 5.135 5.135 0 010-10.27zm0 1.802a3.333 3.333 0 100 6.666 3.333 3.333 0 000-6.666zm5.338-3.205a1.2 1.2 0 110 2.4 1.2 1.2 0 010-2.4z"
                    , SvgAttr.clipRule "evenodd"
                    ]
                    []
                ]

        Website ->
            websiteIcon

        Spotify ->
            Svg.svg
                [ SvgAttr.class "w-5 h-5"
                , SvgAttr.fill "currentColor"
                , SvgAttr.viewBox "0 0 24 24"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Svg.path
                    [ SvgAttr.d "M12 0C5.4 0 0 5.4 0 12s5.4 12 12 12 12-5.4 12-12S18.66 0 12 0zm5.521 17.34c-.24.359-.66.48-1.021.24-2.82-1.74-6.36-2.101-10.561-1.141-.418.122-.779-.179-.899-.539-.12-.421.18-.78.54-.9 4.56-1.021 8.52-.6 11.64 1.32.42.18.479.659.301 1.02zm1.44-3.3c-.301.42-.841.6-1.262.3-3.239-1.98-8.159-2.58-11.939-1.38-.479.12-1.02-.12-1.14-.6-.12-.48.12-1.021.6-1.141C9.6 9.9 15 10.561 18.72 12.84c.361.181.54.78.241 1.2zm.12-3.36C15.24 8.4 8.82 8.16 5.16 9.301c-.6.179-1.2-.181-1.38-.721-.18-.601.18-1.2.72-1.381 4.26-1.26 11.28-1.02 15.721 1.621.539.3.719 1.02.419 1.56-.299.421-1.02.599-1.559.3z"
                    ]
                    []
                ]

        YouTube ->
            Svg.svg
                [ SvgAttr.class "w-5 h-5"
                , SvgAttr.fill "currentColor"
                , SvgAttr.viewBox "0 0 24 24"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Svg.path
                    [ SvgAttr.fillRule "evenodd"
                    , SvgAttr.d "M19.812 5.418c.861.23 1.538.907 1.768 1.768C21.998 8.746 22 12 22 12s0 3.255-.418 4.814a2.504 2.504 0 0 1-1.768 1.768c-1.56.419-7.814.419-7.814.419s-6.255 0-7.814-.419a2.505 2.505 0 0 1-1.768-1.768C2 15.255 2 12 2 12s0-3.255.417-4.814a2.507 2.507 0 0 1 1.768-1.768C5.744 5 11.998 5 11.998 5s6.255 0 7.814.418ZM15.194 12 10 15V9l5.194 3Z"
                    , SvgAttr.clipRule "evenodd"
                    ]
                    []
                ]

        Facebook ->
            Svg.svg
                [ SvgAttr.class "w-5 h-5"
                , SvgAttr.fill "currentColor"
                , SvgAttr.viewBox "0 0 24 24"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Svg.path
                    [ SvgAttr.fillRule "evenodd"
                    , SvgAttr.d "M22 12c0-5.523-4.477-10-10-10S2 6.477 2 12c0 4.991 3.657 9.128 8.438 9.878v-6.987h-2.54V12h2.54V9.797c0-2.506 1.492-3.89 3.777-3.89 1.094 0 2.238.195 2.238.195v2.46h-1.26c-1.243 0-1.63.771-1.63 1.562V12h2.773l-.443 2.89h-2.33v6.988C18.343 21.128 22 16.991 22 12z"
                    , SvgAttr.clipRule "evenodd"
                    ]
                    []
                ]


websiteIcon : Html msg
websiteIcon =
    Svg.svg
        [ SvgAttr.class "w-5 h-5"
        , SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.stroke "currentColor"
        , Attr.attribute "aria-hidden" "true"
        ]
        [ Svg.path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M12 21a9.004 9.004 0 0 0 8.716-6.747M12 21a9.004 9.004 0 0 1-8.716-6.747M12 21c2.485 0 4.5-4.03 4.5-9S14.485 3 12 3m0 18c-2.485 0-4.5-4.03-4.5-9S9.515 3 12 3m0 0a8.997 8.997 0 0 1 7.843 4.582M12 3a8.997 8.997 0 0 0-7.843 4.582m15.686 0A11.953 11.953 0 0 1 12 10.5c-2.998 0-5.74-1.1-7.843-2.918m15.686 0A8.959 8.959 0 0 1 21 12c0 .778-.099 1.533-.284 2.253m0 0A17.919 17.919 0 0 1 12 16.5a17.92 17.92 0 0 1-8.716-2.247m0 0A9.015 9.015 0 0 1 3 12c0-1.605.42-3.113 1.157-4.418"
            ]
            []
        ]


findTodayEvent : List Event.Event -> Maybe Event.Event
findTodayEvent events =
    List.head events


getBand : String -> BackendTask.BackendTask FatalError.FatalError Band
getBand bandId =
    BackendTask.Env.expect "AIRTABLE_JAZZ_TOKEN"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\airTableToken ->
                BackendTask.Http.getWithOptions
                    { url = "https://api.airtable.com/v0/appNxan3bXZ81sXQn/Bands/" ++ bandId
                    , timeoutInMs = Nothing
                    , retries = Nothing
                    , cachePath = Nothing
                    , cacheStrategy = Nothing
                    , expect = BackendTask.Http.expectJson bandDecoder
                    , headers = [ ( "Authorization", "Bearer " ++ airTableToken ) ]
                    }
                    |> BackendTask.allowFatal
            )


getMusicians : List String -> BackendTask.BackendTask FatalError.FatalError (List Musician)
getMusicians musicianIds =
    BackendTask.Env.expect "AIRTABLE_JAZZ_TOKEN"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\airTableToken ->
                musicianIds
                    |> List.map
                        (\musicianId ->
                            BackendTask.Http.getWithOptions
                                { url = "https://api.airtable.com/v0/appNxan3bXZ81sXQn/Musicians/" ++ musicianId
                                , timeoutInMs = Nothing
                                , retries = Nothing
                                , cachePath = Nothing
                                , cacheStrategy = Nothing
                                , expect = BackendTask.Http.expectJson singleMusicianDecoder
                                , headers = [ ( "Authorization", "Bearer " ++ airTableToken ) ]
                                }
                                |> BackendTask.allowFatal
                        )
                    |> BackendTask.combine
            )


bandDecoder : Decoder Band
bandDecoder =
    Decode.field "fields" bandFieldsDecoder


bandFieldsDecoder : Decoder Band
bandFieldsDecoder =
    Decode.map2 Band
        (Decode.field "Band Name" Decode.string)
        socialLinksDecoder


singleMusicianDecoder : Decoder Musician
singleMusicianDecoder =
    Decode.field "fields" musicianDecoder


musiciansDecoder : Decoder (List Musician)
musiciansDecoder =
    Decode.field "records" (Decode.list (Decode.field "fields" musicianDecoder))


musicianDecoder : Decoder Musician
musicianDecoder =
    Decode.map4 Musician
        (Decode.field "Name" Decode.string)
        (Decode.field "Instrument" Decode.string)
        socialLinksDecoder
        headshotDecoder


headshotDecoder : Decoder (Maybe String)
headshotDecoder =
    Decode.maybe 
        (Decode.field "Headshot" 
            (Decode.index 0 
                (Decode.field "url" Decode.string)
            )
        )


socialLinksDecoder : Decoder (List SocialLink)
socialLinksDecoder =
    Decode.map4
        (\instagram facebook youtube website ->
            [ Maybe.map (SocialLink Instagram) instagram
            , Maybe.map (SocialLink Facebook) facebook
            , Maybe.map (SocialLink YouTube) youtube
            , Maybe.map (SocialLink Website) website
            ]
                |> List.filterMap identity
        )
        (Decode.maybe (Decode.field "Instagram" Decode.string))
        (Decode.maybe (Decode.field "Facebook" Decode.string))
        (Decode.maybe (Decode.field "YouTube" Decode.string))
        (Decode.maybe (Decode.field "Website" Decode.string))
