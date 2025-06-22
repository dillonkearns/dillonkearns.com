module Newsletter exposing (Newsletter, NewsletterMetadata, all, decoder)

import BackendTask exposing (BackendTask)
import BackendTask.File
import BackendTask.Glob as Glob
import Date exposing (Date)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import MarkdownCodec
import Time


type alias Newsletter =
    { slug : String
    , filePath : String
    , metadata : NewsletterMetadata
    , publishAt : Date
    }


type alias NewsletterMetadata =
    { title : String
    }


all : BackendTask FatalError (List Newsletter)
all =
    Glob.succeed
        (\filename filePath ->
            case parseFilename filename of
                Just { date, slug } ->
                    filePath
                        |> BackendTask.File.onlyFrontmatter decoder
                        |> BackendTask.allowFatal
                        |> BackendTask.map
                            (\metadata ->
                                Just
                                    { slug = slug
                                    , filePath = filePath
                                    , metadata = metadata
                                    , publishAt = date
                                    }
                            )

                Nothing ->
                    BackendTask.succeed Nothing
        )
        |> Glob.match (Glob.literal "content/newsletters/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.captureFilePath
        |> Glob.toBackendTask
        |> BackendTask.resolve
        |> BackendTask.map (List.filterMap identity)


parseFilename : String -> Maybe { date : Date, slug : String }
parseFilename filename =
    case String.split "-" filename of
        year :: month :: day :: rest ->
            case ( String.toInt year, String.toInt month, String.toInt day ) of
                ( Just y, Just m, Just d ) ->
                    let
                        date =
                            Date.fromCalendarDate y (intToMonth m) d
                    in
                    Just
                        { date = date
                        , slug = String.join "-" rest
                        }

                _ ->
                    Nothing

        _ ->
            Nothing


intToMonth : Int -> Time.Month
intToMonth month =
    case month of
        1 ->
            Time.Jan

        2 ->
            Time.Feb

        3 ->
            Time.Mar

        4 ->
            Time.Apr

        5 ->
            Time.May

        6 ->
            Time.Jun

        7 ->
            Time.Jul

        8 ->
            Time.Aug

        9 ->
            Time.Sep

        10 ->
            Time.Oct

        11 ->
            Time.Nov

        _ ->
            Time.Dec


decoder : Decoder NewsletterMetadata
decoder =
    Decode.map NewsletterMetadata
        (Decode.field "title" Decode.string)
