module Newsletter exposing (Newsletter, NewsletterMetadata, all, decoder)

import BackendTask exposing (BackendTask)
import BackendTask.File
import BackendTask.Glob as Glob
import Date exposing (Date)
import FatalError exposing (FatalError)
import Json.Decode as Decode exposing (Decoder)
import MarkdownCodec


type alias Newsletter =
    { slug : String
    , filePath : String
    , metadata : NewsletterMetadata
    }


type alias NewsletterMetadata =
    { title : String
    , publishAt : Date
    }


all : BackendTask FatalError (List Newsletter)
all =
    Glob.succeed
        (\slug filePath ->
            filePath
                |> BackendTask.File.onlyFrontmatter decoder
                |> BackendTask.allowFatal
                |> BackendTask.map
                    (\metadata ->
                        { slug = slug
                        , filePath = filePath
                        , metadata = metadata
                        }
                    )
        )
        |> Glob.match (Glob.literal "content/newsletters/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.captureFilePath
        |> Glob.toBackendTask
        |> BackendTask.resolve


decoder : Decoder NewsletterMetadata
decoder =
    Decode.map2 NewsletterMetadata
        (Decode.field "title" Decode.string)
        (Decode.field "publishAt" dateDecoder)


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\dateString ->
                case Date.fromIsoString dateString of
                    Ok date ->
                        Decode.succeed date

                    Err error ->
                        Decode.fail error
            )