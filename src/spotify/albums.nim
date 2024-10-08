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
# date  : 2018-09-10

import spotifyuri, spotifyclient
import sequtils, httpcore, strformat, httpclient, asyncdispatch
import objects / [ album, error, paging, copyright, simpletrack, spotifyresponse, jsonunmarshaller, internalunmarshallers ]

const
  GetAlbumPath = "/albums/{id}"
  GetTracksPath = "/albums/{id}/tracks"
  GetAlbumsPath = "/albums"

proc getAlbum*(client: AsyncSpotifyClient,
  id: string, market = ""): Future[Album] {.async.} =
  let
    path = buildPath(GetAlbumPath.fmt, @[newQuery("market", market)])
    response = await client.request(path)
    unmarshaller = newJsonUnmarshaller(copyrightReplaceTargets)
  result = await toResponse[Album](unmarshaller, response)

proc getAlbumTracks*(client: AsyncSpotifyClient,
  id: string, limit = 20, offset = 0,
  market = ""): Future[Paging[SimpleTrack]] {.async.} =
  let
    path = buildPath(GetTracksPath.fmt, @[
      newQuery("market", market),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
  result = await toResponse[Paging[SimpleTrack]](response)

proc getAlbums*(client: AsyncSpotifyClient,
  ids: seq[string] = @[], market = ""): Future[seq[Album]] {.async.} =
  let
    path = buildpath(GetAlbumsPath, @[
      newQuery("ids", ids.foldr(a & "," & b)),
      newQuery("market", market)
    ])
    response = await client.request(path)
    body = await response.body
    unmarshaller = newJsonUnmarshaller(copyrightReplaceTargets)
    code = response.code

  await response.handleError()
  result = toSeq[Album](unmarshaller, body, "albums")
