port module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode

port userlistPort : (Value -> msg) -> Sub msg
port tasklistPort : (Value -> msg) -> Sub msg

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
                , Http.post
                    { url = "/tasks/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "taskToDo", Encode.string model.newTask ) ]
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
            [ div [class "colomne"]
                [h1[][text("To Do")],
                Html.form [ action "/tasks/", id "task-form", method "POST", onSubmit TaskSubmitted ]
                  [ input [ name "taskToDo"
                    , placeholder "Write a task!"
                    , value model.newTask
                    , type_ "text"
                    , onInput TaskUpdated ] []
                  , input [type_ "submit", value "+" ] []
                  ]                
                , ul [ id "task-list" ]
                    (List.map viewTask model.tasks)
                ]
                ,
                div [class "colomne"]
                [h1[][text("In Progress")],
                Html.form [ action "/tasks/", id "task-form", method "POST", onSubmit TaskSubmitted ]
                  [ input [ name "taskInProgress"
                    , placeholder "Write a task!"
                    , value model.newTask
                    , type_ "text"
                    , onInput TaskUpdated ] []
                  , input [type_ "submit", value "+" ] []
                  ]
                , ul [ id "task-list" ]
                    (List.map viewTask model.tasks)
                ]
                ,
                div [class "colomne"]
                [h1[][text("Done")],
                Html.form [ action "/tasks/", id "task-form", method "POST", onSubmit TaskSubmitted ]
                  [ input [ name "taskDone"
                    , placeholder "Write a task!"
                    , value model.newTask
                    , type_ "text"
                    , onInput TaskUpdated ] []
                  , input [type_ "submit", value "+" ] []
                  ]
                ,Progress.progressMulti
    [ [ Progress.value 20, Progress.success, Progress.label "Success" ]
    , [ Progress.value 30, Progress.info, Progress.label "Info" ]
    , [ Progress.value 40, Progress.danger, Progress.label "Danger" ]
    ]
                , ul [ id "task-list" ]
                    (List.map viewTask model.tasks)
                ]
            ]
        ]


viewTask : Task -> Html Msg
viewTask task =
    
    li [ class "task" ]
        [ div [ class "task-header" ]
            [ span [ class "task-author" ]
                [ text task.content]
            , span [ class "task-date" ] [text <| task.authorName ++ "at " ++ task.date ]
            ]
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ userlistPort decodeExternalUserlist,
         tasklistPort decodeExternalTasklist ]
         
main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        ,subscriptions = subscriptions
        }
