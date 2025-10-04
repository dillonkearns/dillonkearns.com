module GenerateNewsletter exposing (run)

import BackendTask exposing (BackendTask)
import BackendTask.Env
import BackendTask.Time
import Cli.Option as Option
import Cli.OptionsParser as OptionsParser
import Cli.Program as Program
import DateFormat
import Event exposing (Event)
import FatalError exposing (FatalError)
import Pages.Script as Script exposing (Script)
import Time


type alias CliOptions =
    {}


run : Script
run =
    Script.withCliOptions program
        (\cliOptions ->
            generateNewsletter
        )


program : Program.Config CliOptions
program =
    Program.config
        |> Program.add
            (OptionsParser.build {}
                |> OptionsParser.withDoc "Generate a newsletter markdown file with upcoming events from Airtable"
            )


generateNewsletter : BackendTask FatalError ()
generateNewsletter =
    BackendTask.map2 Tuple.pair
        Event.getEvents
        BackendTask.Time.now
        |> BackendTask.andThen
            (\( events, currentTime ) ->
                let
                    zone =
                        -- PST/PDT timezone
                        Time.utc

                    -- Filter events for the upcoming month
                    upcomingMonthEvents =
                        filterUpcomingMonthEvents currentTime events

                    currentMonth =
                        -- Get month from the current date
                        DateFormat.format
                            [ DateFormat.monthNameFull ]
                            zone
                            currentTime

                    currentYear =
                        DateFormat.format
                            [ DateFormat.yearNumber ]
                            zone
                            currentTime

                    dateString : String
                    dateString =
                        -- Format as YYYY-MM-DD for the filename
                        DateFormat.format
                            [ DateFormat.yearNumber
                            , DateFormat.text "-"
                            , DateFormat.monthFixed
                            , DateFormat.text "-"
                            , DateFormat.dayOfMonthFixed
                            ]
                            zone
                            currentTime

                    filename : String
                    filename =
                        "content/newsletters/"
                            ++ dateString
                            ++ "-"
                            ++ String.toLower currentMonth
                            ++ "-"
                            ++ currentYear
                            ++ "-shows.md"

                    fileContent =
                        generateMarkdownContent currentMonth upcomingMonthEvents zone
                in
                Script.writeFile
                    { path = filename
                    , body = fileContent
                    }
                    |> BackendTask.allowFatal
                    |> BackendTask.andThen
                        (\_ ->
                            Script.log ("Generated newsletter: " ++ filename)
                        )
            )


filterUpcomingMonthEvents : Time.Posix -> List Event -> List Event
filterUpcomingMonthEvents currentTime events =
    let
        currentYear =
            Time.toYear Time.utc currentTime

        currentMonth =
            Time.toMonth Time.utc currentTime
    in
    events
        |> List.filter
            (\event ->
                let
                    eventYear =
                        Time.toYear Time.utc event.dateTimeStart

                    eventMonth =
                        Time.toMonth Time.utc event.dateTimeStart

                    eventDay =
                        Time.toDay Time.utc event.dateTimeStart

                    currentDay =
                        Time.toDay Time.utc currentTime
                in
                -- Only include events in the current month that are today or later
                eventYear == currentYear && eventMonth == currentMonth && eventDay >= currentDay
            )


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


generateMarkdownContent : String -> List Event -> Time.Zone -> String
generateMarkdownContent monthName events zone =
    let
        frontmatter =
            "---\n"
                ++ "title: \"Live Jazz in "
                ++ monthName
                ++ "\"\n"
                ++ "---\n\n"

        intro =
            "Intro paragraph.\n\n"

        eventsSection =
            "## " ++ monthName ++ " Shows\n\n" ++ formatEvents events zone

        outro =
            "\n## What We're Working On\n\n"
                ++ "[Add details about what you're working on]\n\n"
                ++ "## A Taste of Soir Noir\n\n"
                ++ "[Add YouTube video or other content]\n\n"
                ++ "Hope to see you soon!\n\n"
                ++ "Best,\n\n"
                ++ "Dillon\n\n"
                ++ "P.S. If you know someone who appreciates live jazz, you can [click here and share this post with them](https://dillonkearns.com/newsletters/"
                ++ String.toLower monthName
                ++ "-shows)."
    in
    frontmatter ++ intro ++ eventsSection ++ outro


formatEvents : List Event -> Time.Zone -> String
formatEvents events zone =
    events
        |> List.map (formatEvent zone)
        |> String.join "\n\n"


formatEvent : Time.Zone -> Event -> String
formatEvent zone event =
    let
        dateStr =
            DateFormat.format
                [ DateFormat.dayOfWeekNameFull
                , DateFormat.text ", "
                , DateFormat.monthNameFull
                , DateFormat.text " "
                , DateFormat.dayOfMonthNumber
                ]
                zone
                event.dateTimeStart

        timeStr =
            case event.dateTimeEnd of
                Just endTime ->
                    DateFormat.format
                        [ DateFormat.hourNumber
                        , DateFormat.text ":"
                        , DateFormat.minuteFixed
                        , DateFormat.text "-"
                        ]
                        zone
                        event.dateTimeStart
                        ++ DateFormat.format
                            [ DateFormat.hourNumber
                            , DateFormat.text ":"
                            , DateFormat.minuteFixed
                            , DateFormat.amPmLowercase
                            ]
                            zone
                            endTime

                Nothing ->
                    "TBD"

        venueName =
            event.location.name
    in
    "### "
        ++ event.name
        ++ " at "
        ++ venueName
        ++ "\n"
        ++ "**"
        ++ dateStr
        ++ "** | "
        ++ timeStr
        ++ "  \n"
        ++ "**"
        ++ venueName
        ++ "**\n\n"
        ++ "[Add event description here]"
