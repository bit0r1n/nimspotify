# Copyright 2018 Yoshihiro Tanaka
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

  # http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Yoshihiro Tanaka <contact@cordea.jp>
# date  : 2018-09-20

import json, httpcore, httpclient, asyncdispatch
import error, jsonunmarshaller, internalunmarshallers

proc toResponse*[T: ref object](unmarshaller: JsonUnmarshaller,
  response: AsyncResponse): Future[T] {.async.} =
  let
    body = await response.body
    code = response.code
  if code.is2xx:
    if body == "":
      result = nil
    else:
      result = to[T](unmarshaller, body)
  else:
    let errorResponse = to[ErrorSpotifyResponse](unmarshaller, body, "error")
    var e: SpotifyError
    e.msg = errorResponse.message
    e.status = HttpCode(errorResponse.status)

    raise e

proc toResponse*[T : ref object](response: AsyncResponse
  ): Future[T] {.async.} =
  result = await toResponse[T](newJsonUnmarshaller(), response)

proc handleError*(unmarshaller: JsonUnmarshaller, response: AsyncResponse
  ) {.async.} =
  let
    body = await response.body
    code = response.code
  if not code.is2xx:
    let errorResponse = to[ErrorSpotifyResponse](unmarshaller, body, "error")
    var e: SpotifyError
    e.msg = errorResponse.message
    e.status = HttpCode(errorResponse.status)

    raise e

proc handleError*(response: AsyncResponse
  ) {.async.} =
    await handleError(newJsonUnmarshaller(), response)