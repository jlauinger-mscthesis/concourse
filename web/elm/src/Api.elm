module Api exposing (Method(..), get, ignoreResponse, paginatedGet, post, request)

import Api.Endpoints exposing (Endpoint, toPath)
import Concourse
import Concourse.Pagination exposing (Page, Paginated)
import Http
import Json.Decode exposing (Decoder)
import Network.Pagination exposing (parsePagination)
import Task exposing (Task)
import Url.Builder


type Method
    = Get
    | Post


methodToString : Method -> String
methodToString m =
    case m of
        Get ->
            "GET"

        Post ->
            "POST"


request :
    { endpoint : Endpoint
    , query : List Url.Builder.QueryParameter
    , method : Method
    , headers : List Http.Header
    , body : Http.Body
    , expect : Http.Expect a
    }
    -> Task Http.Error a
request { endpoint, method, headers, body, expect, query } =
    Http.request
        { method = methodToString method
        , headers = headers
        , url = Url.Builder.absolute (toPath endpoint) query
        , body = body
        , expect = expect
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.toTask


get : Endpoint -> Decoder a -> Task Http.Error a
get endpoint decoder =
    request
        { method = Get
        , headers = []
        , endpoint = endpoint
        , query = []
        , body = Http.emptyBody
        , expect = Http.expectJson decoder
        }


paginatedGet : Endpoint -> Maybe Page -> Decoder a -> Task Http.Error (Paginated a)
paginatedGet endpoint page decoder =
    request
        { method = Get
        , headers = []
        , endpoint = endpoint
        , query = Network.Pagination.params page
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (parsePagination decoder)
        }


post : Endpoint -> Concourse.CSRFToken -> Http.Body -> Task Http.Error ()
post endpoint csrfToken body =
    request
        { method = Post
        , headers = [ Http.header Concourse.csrfTokenHeaderName csrfToken ]
        , endpoint = endpoint
        , query = []
        , body = body
        , expect = ignoreResponse
        }


ignoreResponse : Http.Expect ()
ignoreResponse =
    Http.expectStringResponse <| always <| Ok ()
