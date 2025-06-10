module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import Cloudinary
import DateFormat
import Effect exposing (Effect)
import Event exposing (Event, Venue)
import FatalError exposing (FatalError)
import Footer
import Head
import Head.Seo as Seo
import Html exposing (Html, div, h2, iframe, p, text)
import Html.Attributes as Attr
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatefulRoute, StatelessRoute)
import Shared
import Signup
import Svg exposing (path, svg)
import Svg.Attributes as SvgAttr
import Task
import Time
import View exposing (View)


type alias Model =
    { zone : Time.Zone
    }


type Msg
    = GotTimezone Time.Zone


type alias RouteParams =
    {}


type alias Data =
    { events : List Event
    }


type alias ActionData =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , init = init
            , subscriptions = \_ _ _ _ -> Sub.none
            , update = update
            }


init :
    App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect Msg )
init app shared =
    ( { zone = Time.utc
      }
    , Effect.fromCmd (Time.here |> Task.perform GotTimezone)
    )


update :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update app shared msg model =
    case msg of
        GotTimezone zone ->
            ( { model | zone = zone }, Effect.none )


data : BackendTask FatalError Data
data =
    BackendTask.succeed Data
        |> BackendTask.andMap
            Event.getEvents


head :
    App Data ActionData RouteParams
    -> List Head.Tag
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
        , description = "Dillon Kearns Jazz Piano"
        , locale = Nothing
        , title = "Dillon Kearns - Santa Barbara Jazz Pianist"
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app shared model =
    { title = "Dillon Kearns - Santa Barbara Jazz Pianist"
    , body =
        [ Html.div
            [ Attr.class "relative bg-white"
            ]
            [ Html.div
                [ Attr.class "mx-auto max-w-7xl lg:grid lg:grid-cols-12 lg:gap-x-8 lg:px-8"
                ]
                [ Html.div
                    [ Attr.class "px-6 pt-10 pb-24 sm:pb-32 lg:col-span-7 lg:px-0 lg:pt-40 lg:pb-48 xl:col-span-6"
                    ]
                    [ Html.div
                        [ Attr.class "mx-auto max-w-lg lg:mx-0"
                        ]
                        [ Html.img
                            [ Attr.class "h-8"
                            , Attr.src "/keyboard.svg"
                            , Attr.width 51
                            , Attr.height 32
                            , Attr.alt "Dillon KearnsJazz Piano"
                            ]
                            []
                        , Html.div
                            [ Attr.class "hidden sm:mt-32 sm:flex lg:mt-16"
                            ]
                            [ Html.div
                                [ Attr.class "relative rounded-full px-3 py-1 text-sm/6 text-gray-500 ring-1 ring-gray-900/10 hover:ring-gray-900/20"
                                ]
                                [ Html.text "  Next Event: Fox Wine Co., Sunday, March 23, 5:00–7:00 PM. "
                                , Html.a
                                    [ Attr.href "#upcoming-shows"
                                    , Attr.class "font-semibold whitespace-nowrap text-indigo-600"
                                    ]
                                    [ Html.span
                                        [ Attr.class "absolute inset-0"
                                        , Attr.attribute "aria-hidden" "true"
                                        ]
                                        []
                                    , Html.text "See Upcoming Shows "
                                    , Html.span
                                        [ Attr.attribute "aria-hidden" "true"
                                        ]
                                        [ Html.text "→" ]
                                    ]
                                ]
                            ]
                        , Html.h1
                            [ Attr.class "mt-12 text-5xl font-semibold tracking-tight text-pretty text-gray-900 sm:mt-10 sm:text-7xl"
                            ]
                            [ Html.text "Dillon Kearns Jazz Pianist" ]
                        , Html.p
                            [ Attr.class "mt-8 text-lg font-medium text-gray-600 sm:text-xl" ]
                            [ Html.text "Adding charm and character to Santa Barbara’s restaurants, wineries, bars, and private events through timeless Jazz Standards." ]
                        , Html.div
                            [ Attr.class "mt-10 flex items-center gap-x-6"
                            ]
                            [ Route.Contact
                                |> Route.link
                                    [ Attr.class "rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                                    ]
                                    [ Html.text "Inquire About Booking" ]
                            , Html.a
                                [ Attr.href "#event-clips"
                                , Attr.class "text-sm/6 font-semibold text-gray-900"
                                ]
                                [ Html.text "See Event Clips "
                                , Html.span
                                    [ Attr.attribute "aria-hidden" "true"
                                    ]
                                    [ Html.text "→" ]
                                ]
                            ]
                        ]
                    ]
                , Html.div
                    [ Attr.class "relative lg:col-span-5 lg:-mr-8 xl:absolute xl:inset-0 xl:left-1/2 xl:mr-0"
                    ]
                    [ Cloudinary.responsiveImg
                        { altText = "Dillon Kearns"
                        , cloudinaryId = "v1742066379/hero-color_oh0rng.jpg"
                        , cssClass = "aspect-3/2 w-full bg-gray-50 object-cover lg:absolute lg:inset-0 lg:aspect-auto lg:h-full"
                        , baseSize = 1000
                        }
                    ]
                ]
            ]
        , Html.div [ Attr.class "mt-8" ] [ Signup.view ]
        , videoSection
        , eventsSection app.data.events model.zone
        , Footer.footer True
        ]
    }


videoEmbed : String -> Html msg
videoEmbed videoId =
    div
        [ Attr.class "w-full aspect-video bg-gray-200 shadow-lg rounded-xl overflow-hidden" ]
        [ iframe
            [ --Attr.class "w-full h-full"
              Attr.src ("https://www.youtube.com/embed/" ++ videoId)
            , Attr.attribute "frameborder" "0"
            , Attr.attribute "allow" "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            , Attr.attribute "allowfullscreen" "true"
            , Attr.style "width" "100%"
            , Attr.style "height" "700px"
            ]
            []
        ]


videoSection : Html msg
videoSection =
    div
        [ Attr.class "mx-auto mt-32 max-w-7xl px-6 sm:mt-56 lg:px-8" ]
        [ div
            [ Attr.class "mx-auto max-w-2xl lg:text-center" ]
            [ h2
                [ Attr.class "text-3xl font-semibold tracking-tight text-gray-900 sm:text-4xl"
                , Attr.id "event-clips"
                ]
                [ text "Event Clips" ]
            , p
                [ Attr.class "mt-6 text-lg text-gray-600" ]
                [ text "Get a feel for the vibe with recent live clips." ]
            ]
        , div
            [ Attr.class "mx-auto mt-16 max-w-2xl sm:mt-20 lg:mt-24 lg:max-w-none" ]
            [ div
                [ --Attr.class "grid max-w-xl grid-cols-1 gap-x-8 gap-y-12 lg:max-w-none lg:grid-cols-3"
                  -- single centered item for now
                  Attr.class "grid max-w-xl grid-cols-1 gap-x-8 gap-y-12 lg:max-w-none grid-cols-1 place-items-center"
                ]
                [ --googleDriveEmbed "1g1xZb8DNxnxHMQ5kzd6idQkEhJ-O4q7U"
                  --videoEmbed "8c0uz2FoKS8"
                  --videoEmbed "9wXe_-JZu5A"
                  video1

                --https://youtu.be/9wXe_-JZu5A
                ]
            ]
        ]


eventsSection : List Event -> Time.Zone -> Html msg
eventsSection events zone =
    div
        [ Attr.class "mx-auto mt-32 max-w-7xl px-6 sm:mt-56 lg:px-8" ]
        [ div
            [ Attr.class "mx-auto max-w-2xl lg:text-center" ]
            [ h2
                [ Attr.class "text-3xl font-semibold tracking-tight text-gray-900 sm:text-4xl"
                , Attr.id "upcoming-shows"
                ]
                [ text "Upcoming Shows" ]
            ]
        , div
            [ Attr.class "mx-auto mt-8 max-w-2xl sm:mt-20 lg:mt-12 lg:max-w-none" ]
            [ eventsView events zone
            ]
        ]


eventView : Time.Zone -> Event -> Html msg
eventView zone event =
    Html.li [ Attr.class "relative flex gap-x-6 py-6 xl:static" ]
        [ Html.div [ Attr.class "flex-auto" ]
            [ Html.h3 [ Attr.class "pr-10 font-semibold text-gray-900 xl:pr-0" ]
                [ (case event.ticketUrl of
                    Just url ->
                        Html.a
                            [ Attr.href url
                            , Attr.attribute "target" "_blank"
                            ]

                    Nothing ->
                        Html.span
                            []
                  )
                    [ Html.text event.name
                    ]
                ]
            , Html.dl [ Attr.class "mt-2 flex flex-col text-gray-500 xl:flex-row" ]
                [ Html.div [ Attr.class "flex items-start gap-x-3" ]
                    [ Html.dt [ Attr.class "mt-0.5" ]
                        [ calendarIcon
                        ]
                    , Html.dd []
                        [ Html.time
                            [-- TODO
                             --Attr.datetime
                             --    event.dateTimeISO
                            ]
                            [ Html.text
                                --"Sunday, March 27"
                                --event.dateTime
                                (DateFormat.format
                                    [ DateFormat.dayOfWeekNameAbbreviated
                                    , DateFormat.text ", "
                                    , DateFormat.monthNameAbbreviated
                                    , DateFormat.text " "
                                    , DateFormat.dayOfMonthNumber
                                    ]
                                    zone
                                    event.dateTimeStart
                                )
                            ]
                        ]
                    ]
                , Html.div [ Attr.class "mt-2 flex items-start gap-x-3 xl:mt-0 xl:ml-3.5 xl:border-l xl:border-gray-400/50 xl:pl-3.5" ]
                    [ Html.dt [ Attr.class "mt-0.5" ]
                        [ clockIcon ]
                    , Html.dd []
                        [ Html.time
                            [-- TODO
                             --Attr.datetime event.dateTimeISO
                            ]
                            [ Html.text
                                (formatTime zone event.dateTimeStart
                                    ++ " - "
                                    ++ formatTime zone event.dateTimeEnd
                                )
                            ]
                        ]
                    ]
                , Html.div [ Attr.class "min-w-3xs mt-2 flex items-start gap-x-3 xl:mt-0 xl:ml-3.5 xl:border-l xl:border-gray-400/50 xl:pl-3.5" ]
                    [ Html.dt [ Attr.class "mt-0.5" ]
                        [ mapIcon ]
                    , Html.dd []
                        [ Html.a
                            [ Attr.href (Event.googleMapsUrl event)
                            , Attr.target "_blank"
                            ]
                            [ Html.text event.location.name
                            ]
                        ]
                    ]
                , Html.div [ Attr.class "mt-2 flex items-start gap-x-3 xl:mt-0 xl:ml-3.5 xl:border-l xl:border-gray-400/50 xl:pl-3.5" ]
                    [ Html.a
                        [ Attr.href (Event.addToGoogleCalendarUrl zone event)
                        , Attr.class "inline-flex items-center gap-x-2 rounded-md border border-indigo-600 px-4 py-2 text-sm font-semibold text-indigo-600 shadow-sm hover:bg-indigo-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
                        , Attr.target "_blank"
                        ]
                        [ Html.text "Add to Google Calendar"
                        ]
                    ]
                ]
            ]
        ]


formatTime : Time.Zone -> Time.Posix -> String
formatTime zone dateTime =
    DateFormat.format
        [ DateFormat.hourFixed
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        , DateFormat.text " "
        , DateFormat.amPmLowercase
        ]
        zone
        dateTime


calendarIcon : Html msg
calendarIcon =
    svg [ SvgAttr.class "size-5 text-gray-400 fill-indigo-600", SvgAttr.viewBox "0 0 20 20", SvgAttr.fill "currentColor" ]
        [ path [ SvgAttr.d "M5.75 2a.75.75 0 0 1 .75.75V4h7V2.75a.75.75 0 0 1 1.5 0V4h.25A2.75 2.75 0 0 1 18 6.75v8.5A2.75 2.75 0 0 1 15.25 18H4.75A2.75 2.75 0 0 1 2 15.25v-8.5A2.75 2.75 0 0 1 4.75 4H5V2.75A.75.75 0 0 1 5.75 2Zm-1 5.5c-.69 0-1.25.56-1.25 1.25v6.5c0 .69.56 1.25 1.25 1.25h10.5c.69 0 1.25-.56 1.25-1.25v-6.5c0-.69-.56-1.25-1.25-1.25H4.75Z" ] []
        ]


clockIcon : Html msg
clockIcon =
    svg
        [ SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.class "size-6 text-indigo-600 w-5 h-5"
        ]
        [ path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
            ]
            []
        ]


mapIcon : Html msg
mapIcon =
    svg
        [ SvgAttr.fill "none"
        , SvgAttr.viewBox "0 0 24 24"
        , SvgAttr.strokeWidth "1.5"
        , SvgAttr.stroke "currentColor"
        , SvgAttr.class "size-6 text-indigo-600 w-5 h-5"
        ]
        [ path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
            ]
            []
        , path
            [ SvgAttr.strokeLinecap "round"
            , SvgAttr.strokeLinejoin "round"
            , SvgAttr.d "M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z"
            ]
            []
        ]


eventsView : List Event -> Time.Zone -> Html msg
eventsView events zone =
    Html.ol [ Attr.class "mt-4 divide-y divide-gray-100 text-sm/6 lg:col-span-7 xl:col-span-8" ]
        (List.map (eventView zone) events)


twoHours : Int
twoHours =
    2 * 60 * 60 * 1000


googleDriveEmbed : String -> Html msg
googleDriveEmbed driveId =
    Html.div
        [ Attr.class "flex max-w-sm"
        ]
        [ Html.iframe
            [ Attr.src <|
                "https://drive.google.com/file/d/"
                    ++ driveId
                    ++ "/preview"
            , Attr.style "width" "100%"
            , Attr.style "height" "480px"
            , Attr.attribute "allow" "autoplay"
            , Attr.attribute "allowFullScreen" "true"
            ]
            []
        ]


video1 : Html msg
video1 =
    Html.div
        []
        [ Html.iframe
            [ Attr.src "https://www.youtube.com/embed/9wXe_-JZu5A?si=tnr0Ni7pvxM7Z9cZ"
            , Attr.class "w-full bg-gray-200 shadow-lg rounded-xl overflow-hidden aspect-9/16"
            , Attr.style "width" "100%"
            , Attr.style "height" "700px"
            , Attr.title "YouTube video player"
            , Attr.attribute "frameborder" "0"
            , Attr.attribute "allow" "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
            , Attr.attribute "referrerpolicy" "strict-origin-when-cross-origin"
            , Attr.attribute "allowfullscreen" ""
            ]
            []
        ]
