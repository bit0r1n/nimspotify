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
# date  : 2018-09-18

import spotifyuri, spotifyclient
import sequtils, httpclient, asyncdispatch
import objects / [ error, searchresult, simpleplaylist, spotifyresponse, internalunmarshallers ]

const
  SearchPath = "/search"

type
  SearchType* = enum
    TypeAlbum = "album"
    TypeArtist = "artist"
    TypePlaylist = "playlist"
    TypeTrack = "track"

proc internalSearch(client: AsyncSpotifyClient,
  q: string, searchTypes: seq[SearchType], market: string,
  limit, offset: int, includeExternal: string): Future[SearchResult] {.async.} =
  let
    path = buildPath(SearchPath, @[
      newQuery("q", q),
      newQuery("type", searchTypes
        .map(proc (x: SearchType): string = $x)
        .foldr(a & "," & b)),
      newQuery("market", market),
      newQuery("limit", $limit),
      newQuery("offset", $offset),
      newQuery("include_external", includeExternal)
    ])
    response = await client.request(path)
  result = await toResponse[SearchResult](response)

proc search*(client: AsyncSpotifyClient,
  q: string, searchTypes: seq[SearchType], market = "",
  limit = 20, offset = 0): Future[SearchResult] {.async.} =
  result = await client.internalSearch(q, searchTypes, market, limit, offset, "")

proc searchWithAudio*(client: AsyncSpotifyClient,
  q: string, searchTypes: seq[SearchType], market = "",
  limit = 20, offset = 0): Future[SearchResult] {.async.} =
  result = await client.internalSearch(q, searchTypes, market, limit, offset, "audio")
