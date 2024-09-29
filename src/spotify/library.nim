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
# date  : 2018-09-15

import spotifyuri, spotifyclient
import json, sequtils, httpclient, asyncdispatch
import objects / [ error, paging, copyright,  savedalbum, savedtrack, spotifyresponse, jsonunmarshaller, internalunmarshallers ]

const
  IsSavedAlbumsPath = "/me/albums/contains"
  IsSavedTracksPath = "/me/tracks/contains"
  GetSavedAlbumsPath = "/me/albums"
  GetSavedTracksPath = "/me/tracks"
  DeleteSavedAlbumsPath = "/me/albums"
  DeleteSavedTracksPath = "/me/tracks"
  SaveAlbumsPath = "/me/albums"
  SaveTracksPath = "/me/tracks"

proc internalIsSaved(client: AsyncSpotifyClient,
  path: string, ids: seq[string]): Future[seq[bool]] {.async.} =
  let
    path = buildPath(path, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()

  let json = parseJson body
  for elem in json.elems:
    result.add elem.getBool

proc isSavedAlbums*(client: AsyncSpotifyClient,
  ids: seq[string]): Future[seq[bool]] {.async.} =
  result = await client.internalIsSaved(IsSavedAlbumsPath, ids)

proc isSavedTracks*(client: AsyncSpotifyClient,
  ids: seq[string]): Future[seq[bool]] {.async.} =
  result = await client.internalIsSaved(IsSavedTracksPath, ids)

proc getSavedAlbums*(client: AsyncSpotifyClient,
  limit = 20, offset = 0,
  market = ""): Future[Paging[SavedAlbum]] {.async.} =
  let
    path = buildPath(GetSavedAlbumsPath, @[
      newQuery("market", market),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    unmarshaller = newJsonUnmarshaller(copyrightReplaceTargets)
    response = await client.request(path)
  result = await toResponse[Paging[SavedAlbum]](unmarshaller, response)

proc getSavedTracks*(client: AsyncSpotifyClient,
  limit = 20, offset = 0,
  market = ""): Future[Paging[SavedTrack]] {.async.} =
  let
    path = buildPath(GetSavedTracksPath, @[
      newQuery("market", market),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
  result = await toResponse[Paging[SavedTrack]](response)

proc deleteSavedAlbums*(client: AsyncSpotifyClient,
  ids: seq[string] = @[]) {.async.} =
  let
    path = buildPath(DeleteSavedAlbumsPath, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpDelete)
  await response.handleError()

proc deleteSavedTracks*(client: AsyncSpotifyClient,
  ids: seq[string] = @[]) {.async.} =
  let
    path = buildPath(DeleteSavedTracksPath, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpDelete)
  await response.handleError()

proc saveAlbums*(client: AsyncSpotifyClient,
  ids: seq[string] = @[]) {.async.} =
  let
    path = buildPath(SaveAlbumsPath, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc saveTracks*(client: AsyncSpotifyClient,
  ids: seq[string] = @[]) {.async.} =
  let
    path = buildPath(SaveTracksPath, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()
