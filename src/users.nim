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
# date  : 2018-09-02

import httpclient
import spotifyclient
import asyncdispatch
import objects / user
import objects / publicuser
import objects / jsonunmarshaller
import objects / internalunmarshallers

const
  GetMePath = "/me"
  GetUserPath = "/users/"

proc getCurrentUser*(client: SpotifyClient | AsyncSpotifyClient): Future[User] {.multisync.} =
  let
    response = await client.request(GetMePath)
    body = await response.body
  result = to[User](newJsonUnmarshaller(), body)

proc getUser*(client: SpotifyClient | AsyncSpotifyClient,
  id: string): Future[PublicUser] {.multisync.} =
  let
    response = await client.request(GetUserPath & id)
    body = await response.body
  result = to[PublicUser](newJsonUnmarshaller(), body)
