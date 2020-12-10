module UI.Comment exposing (viewCommentsSection)

{-| UI modules for rendering a tree of comments.
-}

import Ant.Button as Btn exposing (button)
import Ant.Typography.Text as Text exposing (Text, text)
import Api.Input exposing (Comment, CommentTree, CommentMap, Cuid)
import Css exposing (..)
import Html.Styled as S exposing (toUnstyled, fromUnstyled)
import Html.Styled.Attributes exposing (css)
import Time
import RemoteData exposing (WebData)
import Dict

type alias StyledHtml a = S.Html a

type alias TimeFormatter = Time.Posix -> String



type CommentPointers
    = Simple (List Cuid)
    | Async (WebData (List Cuid))


renderText : Text -> StyledHtml msg
renderText = Text.toHtml >> fromUnstyled


strongText : String -> StyledHtml msg
strongText val =
    text val
    |> Text.strong
    |> renderText


primaryText : String -> StyledHtml msg
primaryText val =
    text val
    |> Text.withType Text.Primary
    |> renderText



secondaryText : String -> StyledHtml msg
secondaryText val =
    text val
    |> Text.withType Text.Secondary
    |> renderText




viewSingleComment : TimeFormatter -> CommentMap -> Comment -> StyledHtml msg
viewSingleComment formatter commentMap comment =
    let
        styles =
            [ marginBottom (px 15)
            ]

        authorName =
            S.span [ css [ marginRight (px 10) ] ]
                [ strongText comment.anonymousAuthorName
                ]
    in
    S.div [ ]
        [ authorName
        , secondaryText <| formatter comment.createdAt
        , S.div [ css styles ] [ primaryText comment.body ]
        , viewComments formatter (Async comment.replyIds) commentMap
        ]


viewComments_ : TimeFormatter -> List Cuid -> CommentMap -> StyledHtml msg
viewComments_ formatter pointers commentMap =
    if List.length pointers == 0 then
        S.div [] []
    else
        let
            comments =
                Dict.values commentMap
                |> List.filter (\comment -> List.member comment.id pointers)
        in
        S.div
            [ css [ marginLeft (px 15) ] ]
            (List.map (viewSingleComment formatter commentMap) comments)


{-| 
    @arg formatter
        a function that formats Posix timestamps into human readable "distance" strings.
        i.e. "5 minutes ago"

    @arg pointers
        cuid pointers that represent the current level of comments to be rendered in a recursive
        tree of comments. Can be Simple, i.e. they are immediately loaded, or Async, meaning we have to do
        a subsequent round-trip to the back end to get this information.

    @arg commentTree
        a flattened hashmap that represents a recursive tree of comments (i.e. just like Reddit)
-}
viewComments : TimeFormatter -> CommentPointers -> CommentMap -> StyledHtml msg
viewComments formatter pointers commentTree =
    case pointers of
        Simple pointerList ->
            viewComments_ formatter pointerList commentTree

        Async webDataList ->
            case webDataList of
                RemoteData.NotAsked ->
                    let
                        loadMoreBtn =
                            button "load more comments"
                            |> Btn.withType Btn.Link
                            |> Btn.toHtml
                            |> fromUnstyled
                    in
                    S.div [] [ loadMoreBtn ]

                RemoteData.Loading ->
                    S.div [] [ S.text "loading" ]

                RemoteData.Failure e -> 
                    S.div [] [ S.text "error loading more comments" ]

                RemoteData.Success replyPointers ->
                    viewComments_ formatter replyPointers commentTree




viewCommentsSection : TimeFormatter -> CommentTree -> StyledHtml msg
viewCommentsSection formatter { topLevelComments, comments }=
    S.div
        [ css [ marginLeft (px -15) ] ]
        [ viewComments formatter (Simple topLevelComments) comments ]

