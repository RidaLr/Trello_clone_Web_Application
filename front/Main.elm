port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


type alias Model =
    { tasks : List Task
    , users : List User
    , newTask : String
    }


type alias Task =
    { authorName : String
    , content : String
    , date : String
    , status : String
    }


type alias User =
    { name : String
    , status : UserStatus
    , rowid : Int
    }

type TaskStatus
    = ToDo
    | InProgress
    | Done
    
type UserStatus
    = Disconnected
    | Available


type Msg
    = GotUserlist (List User)
    | GotTasks (List Task)
    | DecodeError Decode.Error
    | TaskUpdated String
    | TaskSubmitted
    | NoOp


userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (Decode.field "name" Decode.string)
        (Decode.field "status" userStatusDecoder)
        (Decode.field "rowid" Decode.int)


userStatusDecoder : Decoder UserStatus
userStatusDecoder =
    Decode.string
        |> Decode.andThen
            (\status ->
                case status of
                    "DISCONNECTED" ->
                        Decode.succeed Disconnected

                    "AVAILABLE" ->
                        Decode.succeed Available

                    _ ->
                        Decode.fail ("unknown status " ++ status)
            )

taskStatusDecoder : Decoder TaskStatus
taskStatusDecoder =
    Decode.string
        |> Decode.andThen
            (\status ->
                case status of
                    "ToDo" ->
                        Decode.succeed ToDo

                    "InProgress" ->
                        Decode.succeed InProgress
                    
                    "Done" ->
                        Decode.succeed Done
                        
                    _ ->
                        Decode.fail ("unknown status " ++ status)
            )


taskDecoder : Decoder Task
taskDecoder =
    Decode.map4 Task
        (Decode.field "author_name" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "status" Decode.string)


decodeExternalTasklist : Value -> Msg
decodeExternalTasklist val =
    case Decode.decodeValue (Decode.list taskDecoder) val of
        Ok tasklist ->
            GotTasks tasklist

        Err err ->
            DecodeError err



decodeExternalUserlist : Value -> Msg
decodeExternalUserlist val =
    case Decode.decodeValue (Decode.list userDecoder) val of
        Ok userlist ->
            GotUserlist userlist

        Err err ->
            DecodeError err


initialModel : Model
initialModel =
    { tasks = []
    , users = []
    , newTask = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUserlist users ->
            ( { model | users = users }, Cmd.none )

        GotTasks tasks ->
            ( { model | tasks = tasks }, Cmd.none )

        TaskUpdated newTask ->
            ( { model | newTask = newTask }, Cmd.none )

        TaskSubmitted ->
            if model.newTask == "" then
                ( model, Cmd.none )

            else
                ( { model | newTask = "" }
                , Http.task
                    { url = "/tasks/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "content", Encode.string model.newTask ) ]
                    }
                )

        DecodeError err ->
            let
                _ =
                    Debug.log "Decode error" err
            in
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



view : Model -> Html Msg
view model =
    main_ [ id "main-content" ]
        [ section [ id "user-list" ]
            [ header []
                [ text "List of users  " ]
            , ul []
                (List.map viewUser model.users)
            ]
        , section [ id "tasks" ]
            [ Html.form [ action "/tasks/", id "task-form", method "POST", onSubmit TaskSubmitted ]
                [ input
                    [ name "content"
                    , placeholder "Say something nice!"
                    , value model.newTask
                    , type_ "text"
                    , onInput TaskUpdated
                    ]
                    []
                , input [ type_ "submit", value "Share!" ] []
                ]
            , ul [ id "task-list" ]
                (List.map viewTask model.tasks)
            ]
        ]


viewTask : Task -> Html Msg
viewTask task =
    li [ class "task" ]
        [ div [ class "task-header" ]
            [ span [ class "task-author" ]
                [ text task.authorName ]
            , span [ class "task-date" ] [ text <| "at " ++ task.date ]
            ]
        , div [ class "task-content" ] [ text task.content ]
        ]


viewUser : User -> Html Msg
viewUser user =
    li []
        [ text <|
            (case user.status of
                Available ->
                    "✔️ "

                Disconnected ->
                    "⚪ "
            )
                ++ user.name
        ]

        
main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        ,subscriptions = always Sub.none
        }
