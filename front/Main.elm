port module Main exposing (main)

import Bootstrap.Accordion as Accordion
import Bootstrap.Card.Block as Block
import Bootstrap.Table as Table
import Bootstrap.Button as Button
import Bootstrap.Progress as Progress
import Bootstrap.ListGroup as ListGroup
import Browser
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
 

port userlistPort : (Value -> msg) -> Sub msg
port tasklistPort : (Value -> msg) -> Sub msg
port columnlistPort : (Value -> msg) -> Sub msg
port worklistPort : (Value -> msg) -> Sub msg
port sendData : String -> Cmd msg
port receiveData : (Int -> msg) -> Sub msg


type alias Model =
    { tasks : List Task
    , columns : List Column
    , works : List Work
    , users : List User
    , newTask : String
    , newColumn : String
    , newTable : String
    , table_id : Int
    , column_id : Int
    , currentWorkId : Int
    , currentColumnId : Int
    , tasksAux : List Task
    }


type alias Task =
    { column_id : Int --authorName : String
    , content : String
    , date : String
    , status : String
    , visible : Bool
    }


type alias User =
    { name : String
    , status : UserStatus
    , rowid : Int
    }
    

type alias Column =
    { title : String,
    rowid   : Int,
    table_id: Int,
    content : String,
    author_id : String,
    --status : String,
    column_id : Int,
    visible : Bool
    }
  
type alias Work =
    { title : String,
    authorName : String,
    date : String,
    rowid : Int
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
    | GotColumns (List Column)
    | GotWorks (List Work)
    | DecodeError Decode.Error
    | TaskUpdated String
    | TableUpdated String
    | TaskSubmitted
    | TableSubmitted
    | SendDataToJS String
    | ReceivedDataFromJS Int
   -- | LoadTableSubmitted
    | ColumnSubmitted
    | NoOp


userDecoder : Decoder User
userDecoder =
    Decode.map3 User
        (Decode.field "name" Decode.string)
        (Decode.field "status" userStatusDecoder)
        (Decode.field "rowid" Decode.int)

columnDecoder : Decoder Column
columnDecoder =
    Decode.map7 Column
        (Decode.field "title" Decode.string)
        (Decode.field "rowid" Decode.int)
        (Decode.field "table_id" Decode.int)
        (Decode.field "content" Decode.string)
        (Decode.field "author_id" Decode.string)
        (Decode.field "column_id" Decode.int)
        (Decode.field "visible" Decode.bool)

workDecoder : Decoder Work
workDecoder =
    Decode.map4 Work
        (Decode.field "title" Decode.string)
        (Decode.field "authorName" Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "rowid" Decode.int)


taskDecoder : Decoder Task
taskDecoder =
    Decode.map5 Task
        (Decode.field "column_id" Decode.int)
        (Decode.field "content" Decode.string)
        (Decode.field "date" Decode.string)
        (Decode.field "status" Decode.string)
        (Decode.field "visible" Decode.bool)


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

decodeExternalWorklist : Value -> Msg
decodeExternalWorklist val =
    case Decode.decodeValue (Decode.list workDecoder) val of
        Ok worklist ->
            GotWorks worklist
        Err err ->
            DecodeError err
            
decodeExternalColumnlist : Value -> Msg
decodeExternalColumnlist val =
    case Decode.decodeValue (Decode.list columnDecoder) val of
        Ok columnlist ->
            GotColumns columnlist

        Err err ->
            DecodeError err
            
chooseColums : Int -> Column -> Column
chooseColums  workId column = 
                if(column.table_id /= workId) then
                  {column | visible = False}
                else
                {column | visible = True}
                
chooseTasks : Int -> Column -> Column
chooseTasks  columnId task = 
                if(task.column_id /= columnId) then
                  {task | visible = False}
                else
                {task | visible = True}

initialModel : Model
initialModel =
    { tasks = []
    , columns = []
    , users = []
    , works = []
    , newTask = ""
    , newColumn = ""
    , newTable = ""
    , table_id = 0
    , column_id = 0
    , currentWorkId = 1
    , currentColumnId = 1
    , tasksAux = []
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
    
        SendDataToJS data ->
            ( model, sendData data )

        ReceivedDataFromJS data ->
            ( { model | column_id =data}, Cmd.none )
            
        GotUserlist users ->
            ( { model | users = users }, Cmd.none )

        GotColumns columns ->
            ( { model | columns = columns }, Cmd.none )
            
        GotTasks tasks ->
            ( { model | tasks = tasks }, Cmd.none )
        
        GotWorks works ->
            ( { model | works = works }, Cmd.none )

        TaskUpdated newTask ->
            ( { model | newTask = newTask }, Cmd.none )

        TableUpdated newTable ->
            ( { model | newTable = newTable }, Cmd.none )
        {-
        LoadTableSubmitted id ->
          ( { model | columns = id }, Cmd.none )-}

        TaskSubmitted ->
            if model.newTask == "" then
                ( model, Cmd.none )

            else
                ( { model | newTask = "" }
                , Http.post
                    { url = "/tasks/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "content", Encode.string model.newTask ) ]
                    }
                )
                
        ColumnSubmitted ->
            if model.newColumn == "" then
                ( model, Cmd.none )

            else
                ( { model | newColumn = "" }
                , Http.post
                    { url = "/tasks/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "content", Encode.string model.newTask ) ]
                    }
                )
       
            
        TableSubmitted ->
            if model.newTable == "" then
                ( model, Cmd.none )

            else
                ( { model | newTable = "" }
                , Http.post
                    { url = "/addTable/"
                    , expect = Http.expectWhatever (\_ -> NoOp)
                    , body = Http.jsonBody <| Encode.object [ ( "content", Encode.string model.newTable )]
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
    --section [id "user-list" ]
        --[ button [ onClick SendDataToJS ]
       --    [ text "Send Data to JavaScript" ]
      --  , br [] []
        --, br [] []
     --   ,ul [][li[][ text ("Data received from JavaScript: " ++ String.fromInt(model.column_id))]]
   --     ]
    main_ [ id "m-content" ]
        [ 
        section [ id "user-list" ]
            [ header []
                [ text ("Your Team ") ]
            , ul []
                (List.map viewUser model.users)
            ,text(String.fromInt(model.column_id))]
        ]
            
 
                                  
      {- , section [ id "tabls" ]
            [ Html.form [ action "/addTable/", id "table-form", method "POST", onSubmit TableSubmitted ]
                [ input
                    [ name "content"
                    , placeholder "Enter the name of the table !"
                    , value model.newTable
                    , type_ "text"
                    , onInput TableUpdated
                    ]
                    []
                , input [ type_ "submit", value "Share!" ] []
                ]
                ,
                div[class "view-work"][ul [class "View-work"]
                (List.map viewWork model.works)]
                ,
    div[class "view-colomne"] (List.map viewColumn model.columns)
    ]
        -}
        {-Table.simpleTable
    ( Table.simpleThead
        [ (List.map viewColumn model.columns)
        ,Table.th [] [ text "Col 1" ]
        , Table.th [] [ text "Col 2" ]
        , Table.th [] [ text "Col 3" ]
        ]
    , Table.tbody []
        [ Table.tr []
            [ Table.td [] [ text "Hello" ]
            , Table.td [] [ text "Hello" ]
            , Table.td [] [ text "Hello" ]
            ]
        , Table.tr []
            [ Table.td [] [ text "There" ]
            , Table.td [] [ text "There" ]
            , Table.td [] [ text "There" ]
            ]
        , Table.tr []
            [ Table.td [] [ text "Dude" ]
            , Table.td [] [ text "Dude" ]
            , Table.td [] [ text "Dude" ]
            ]
        ]
    )
          -}          
                {-div [class "colomne"]
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
                  [ input [ name "content"
                    , placeholder "Write a task!"
                    , value model.newTask
                    , type_ "text"
                    , onInput TaskUpdated ] []
                  , input [type_ "submit", value "+" ] []
                  ]
    -}
             --   , ul [ id "task-list" ]
               --     (List.map viewColonne model.columns)
                --]
                --section [ id "work-list" ]
            --[ header []
              --  [ text "Tables " ]
             
            
        --]


    

viewTableau: Work -> Html Msg
viewTableau tab= 
     li [] [ Html.text tab.title
       
     ,Html.form [action "/add-column/", method "POST", id "colonn-form" {-, onSubmit ColonneSubmited-}]
                      [ input
                          [ name "column", placeholder "ajouter une colonne", type_ "text", name "modifier"{-, onInput ColonneUpdated-}] []
                      , input
                          [ value "add colonne", type_ "submit" ] []
                      , input
                          [ name "idtabe", value (String.fromInt (tab.rowid)) , type_ "hidden" ] []
             ]
   -- ,Html.ul [] (List.map viewColonne tab.colonnes)
            ]

    
viewColonne: Column -> Html Msg  
viewColonne col =
        
                li [] [text col.title,

                        Html.form [action "/add-tache/", method "POST", id "tacheform" {-, onSubmit TacheSubmited-}]
                            [ input
                                [ name "task", placeholder "ajouter une Tache", type_ "text", name "modifier"{-, onInput TacheUpdated-}] []
                            , input
                                [ value "add tache", type_ "submit" ] []
                            , input
                                [ name "colid", value (String.fromInt (col.rowid)), type_ "hidden" ] []
                       ]
                  --     , Html.ul [] ( List.map viewTache col.taches )

                ]
       
              
                  
viewTache: Column -> Html Msg  
viewTache task=
        
        li [] [text task.content]


viewTask0 : Column -> String
viewTask0 task =
    case task.title of
        "Done" ->
            --li [class "done" ]
              task.content
              --  , button [ onClick <| ClikedOnDoneButton id ] [ text "Done!" ]
            --    ]

        "ToDo" ->
            --li [ class "todo" ] [ 
            task.content
            
        "InProgress" ->
            --li [ class "urginprogressent" ]
               -- [ 
                task.content
                --, button [ onClick <| ClikedOnDoneButton id ] [ text "Done!" ]
              --  ]

        _ ->
          "⚠️"

viewColumn1 : Column -> Html msg
viewColumn1 column=
  li [] 
          [ text column.title,
          ul[][
          
                case column.rowid == column.column_id of
                    True ->
                                li [] 
                                  [ text column.content]
                                    
                    _ ->
                        li [] 
                                  [ text "error"]

          ]]
    
getid : Column -> Int
getid col =
  col.rowid

viewTask : Task -> Html Msg
viewTask task =
    
    li [ class "task" ]
        [ div [ class "task-header" ]
            [ span [ class "task-author" ]
                [ text task.content],span [ class "task-progress" ][Progress.progress [ Progress.value 20 , Progress.success, Progress.label "Success"]]
           -- , span [ class "task-date" ] [text <| task.authorName ++ " at " ++ task.date ]
            ]
        ]

viewTask2 : Task -> Html Msg
viewTask2 task =
    
    tr []
        [ td [] [ text <| task.content]
--        [ td [] [ text <| task.content ++" by "++ task.authorName ]
        ]

viewWork : Work -> Html Msg
viewWork work =
    li [class "work" ]
        [ div [ class "work-header" ]
            [ span [ class "work-view" ]
                [button [ onClick TaskSubmitted ] [text work.title]]
            ]
        ]
                --[ a [href ("/work/"++String.fromInt(work.rowid))] [text work.title ] ]]]
        --li [] [button [ onClick Decrement ] [text work.title]]


viewColumn : Column -> Html msg
viewColumn column=
  if(column.visible == True && (getid column) == column.column_id) then
    
    div[class "colomne"][
      p[] [text (column.title)],
      ListGroup.ul [ListGroup.li [] [ text (viewTask0 column)]]
    ]
    else
      li [class "colomne" ]
        [ div [ class "column-header" ]
            [ span [ class "work-view" ]
                [text ("ERROR")]
            ]
        ]
   -- ListGroup.ul [ListGroup.li [] [ text "Should to nothing" ]]

        
            
viewt : Int -> Column -> String
viewt id col = 
  (chooseTasks id col).content

-- Any word with more than 3 characters is so long!
isLongWord : Column -> Bool
isLongWord col =
    col.column_id==col.rowid

longWordsFromCatStory :List Column -> List Column
longWordsFromCatStory columns= 
    List.filter isLongWord columns
  
viewTaskForColumn : Task -> ListGroup.Item msg
viewTaskForColumn task = 
  if(task.visible==True) then
    ListGroup.li [] [text (task.content)]
  else
    ListGroup.li [] [ text "Should to nothing" ]

  --th [] [ text column.title ]
  --Table.th [] [ text column.title ]
{-    tr []
                [ th [] [ text column.title ]
               
                ]
  -}  {-li [ class "colue" ]
        [ div [ class "column-header" ]
            [ span [ class "column-title" ]
                [ text column.title]
            ]
        ]-}

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
         tasklistPort decodeExternalTasklist,
         columnlistPort decodeExternalColumnlist,
         worklistPort decodeExternalWorklist,
         receiveData ReceivedDataFromJS]
         
main : Program () Model Msg
main =
    Browser.element
        { init = \() -> ( initialModel, Cmd.none )
        , view = view
        , update = update
        ,subscriptions = subscriptions
        }
