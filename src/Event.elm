module Event exposing (Event, Venue, addToGoogleCalendarUrl, getEvents, googleMapsUrl)

import BackendTask exposing (BackendTask)
import BackendTask.Env
import BackendTask.Http
import DateFormat
import FatalError exposing (FatalError)
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Time exposing (Posix, Zone)
import TimeZone
import Url


type alias Event =
    { name : String
    , dateTimeStart : Time.Posix
    , dateTimeEnd : Maybe Time.Posix
    , location : Venue
    , bandId : Maybe String -- ID of the linked band record
    , musicianIds : List String -- IDs of the linked musician records
    , ticketUrl : Maybe String -- link to the ticket page if available
    }


type alias Venue =
    { name : String
    , googleMapsNameWithAddress : String
    , webSite : Maybe String -- if the venue has a web site
    }


formatGoogleTime : Time.Zone -> Time.Posix -> String
formatGoogleTime zone posix =
    DateFormat.format
        [ DateFormat.yearNumber
        , DateFormat.monthFixed
        , DateFormat.dayOfMonthFixed
        , DateFormat.text "T"
        , DateFormat.hourMilitaryFixed
        , DateFormat.minuteFixed
        , DateFormat.secondFixed
        ]
        zone
        posix


addToGoogleCalendarUrl : Time.Zone -> Event -> String
addToGoogleCalendarUrl zone event =
    let
        detailsParam =
            case event.ticketUrl of
                Just url ->
                    "&details=" ++ Url.percentEncode ("More info: " ++ url)

                Nothing ->
                    ""

        endTimeString =
            case event.dateTimeEnd of
                Just endTime ->
                    formatGoogleTime zone endTime

                Nothing ->
                    -- If no end time, use start time + 2 hours as default
                    formatGoogleTime zone
                        (Time.millisToPosix
                            (Time.posixToMillis event.dateTimeStart + (2 * 60 * 60 * 1000))
                        )
    in
    "https://calendar.google.com/calendar/render?action=TEMPLATE"
        ++ "&text="
        ++ Url.percentEncode event.name
        ++ "&dates="
        ++ formatGoogleTime zone event.dateTimeStart
        ++ "/"
        ++ endTimeString
        ++ "&location="
        ++ Url.percentEncode event.location.googleMapsNameWithAddress
        ++ detailsParam


eventsDecoder : Decoder (List Event)
eventsDecoder =
    Decode.field "records" (Decode.list (Decode.field "fields" recordDecoder))


recordDecoder : Decoder Event
recordDecoder =
    Decode.map7 Event
        (Decode.field "Event Title" Decode.string)
        (Decode.field "Start Date/Time" Iso8601.decoder)
        endTimeDecoder
        venueDecoder
        bandIdDecoder
        musicianIdsDecoder
        (Decode.succeed Nothing {- TODO -})


endTimeDecoder : Decoder (Maybe Posix)
endTimeDecoder =
    Decode.maybe (Decode.field "Duration" Decode.int)
        |> Decode.andThen
            (\maybeDuration ->
                case maybeDuration of
                    Just durationSecs ->
                        Decode.map
                            (\startTime ->
                                Just
                                    (Time.millisToPosix
                                        (Time.posixToMillis startTime + (durationSecs * 1000))
                                    )
                            )
                            (Decode.field "Start Date/Time" Iso8601.decoder)

                    Nothing ->
                        Decode.succeed Nothing
            )


venueDecoder : Decoder Venue
venueDecoder =
    Decode.map3 Venue
        (Decode.field "Venue Name" (Decode.index 0 Decode.string))
        (Decode.field "Google Maps Location" (Decode.index 0 Decode.string))
        (Decode.succeed Nothing {- TODO -})


bandIdDecoder : Decoder (Maybe String)
bandIdDecoder =
    Decode.maybe (Decode.field "Band" (Decode.index 0 Decode.string))


musicianIdsDecoder : Decoder (List String)
musicianIdsDecoder =
    Decode.field "Musicians" (Decode.list Decode.string)
        |> Decode.maybe
        |> Decode.map (Maybe.withDefault [])


getEvents : BackendTask FatalError (List Event)
getEvents =
    BackendTask.Env.expect "AIRTABLE_JAZZ_TOKEN"
        |> BackendTask.allowFatal
        |> BackendTask.andThen
            (\airTableToken ->
                BackendTask.Http.getWithOptions
                    { url = "https://api.airtable.com/v0/appNxan3bXZ81sXQn/Events?maxRecords=10&view=Upcoming%20Shows"
                    , timeoutInMs = Nothing
                    , retries = Nothing
                    , cachePath = Nothing
                    , cacheStrategy = Nothing
                    , expect = BackendTask.Http.expectJson eventsDecoder
                    , headers = [ ( "Authorization", "Bearer " ++ airTableToken ) ]
                    }
                    |> BackendTask.allowFatal
            )


googleMapsUrl : Event -> String
googleMapsUrl event =
    "https://www.google.com/maps/search/?api=1&query=" ++ Url.percentEncode event.location.googleMapsNameWithAddress
