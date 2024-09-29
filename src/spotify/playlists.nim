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
# date  : 2018-09-17

import spotifyuri, spotifyclient
import json, base64, sequtils, strformat, httpclient, asyncdispatch
import objects / [ error, image, paging, snapshot, playlist, playlisttrack, simpleplaylist, spotifyresponse, internalunmarshallers ]

const
  PostTracksToPlaylistPath = "/playlists/{playlistId}/tracks"
  ChangePlaylistDetailsPath = "/playlists/{playlistId}"
  PostPlaylistPath = "/users/{userId}/playlists"
  GetUserPlaylistsPath = "/me/playlists"
  GetPlaylistsPath = "/users/{userId}/playlists"
  GetPlaylistCoverImagePath = "/playlists/{playlistId}/images"
  GetPlaylistPath = "/playlists/{playlistId}"
  GetPlaylistTracksPath = "/playlists/{playlistId}/tracks"
  DeleteTracksFromPlaylistPath = "/playlists/{playlistId}/tracks"
  ReorderPlaylistTracksPath = "/playlists/{playlistId}/tracks"
  ReplacePlaylistTracksPath = "/playlists/{playlistId}/tracks"
  UploadCustomPlaylistCoverImagePath = "/playlists/{playlistId}/images"

proc postTracksToPlaylist*(client: AsyncSpotifyClient,
  playlistId: string, uris: seq[string],
  position = -1): Future[Snapshot] {.async.} =
  var body = %* {"uris": uris}
  if position != -1:
    body["position"] = %* position
  let
    path = buildPath(PostTracksToPlaylistPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPost)
  result = await toResponse[Snapshot](response)

proc buildBody(name, description: string): JsonNode =
  result = newJObject()
  if name != "":
    result["name"] = %* name
  if description != "":
    result["description"] = %* description

proc changePlaylistDetails*(client: AsyncSpotifyClient,
  playlistId: string, name, description = "") {.async.} =
  let
    body = buildBody(name, description)
    path = buildPath(ChangePlaylistDetailsPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc changePlaylistDetails*(client: AsyncSpotifyClient,
  playlistId: string, public: bool,
  name, description = "") {.async.} =
  var body = buildBody(name, description)
  body["public"] = %* public
  let
    path = buildPath(ChangePlaylistDetailsPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc changePlaylistDetails*(client: AsyncSpotifyClient,
  playlistId: string, collaborative: bool,
  name, description = "") {.async.} =
  var body = buildBody(name, description)
  body["collaborative"] = %* collaborative
  let
    path = buildPath(ChangePlaylistDetailsPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc changePlaylistDetails*(client: AsyncSpotifyClient,
  playlistId: string, public, collaborative: bool,
  name, description = "") {.async.} =
  var body = buildBody(name, description)
  body["public"] = %* public
  body["collaborative"] = %* collaborative
  let
    path = buildPath(ChangePlaylistDetailsPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc postPlaylist*(client: AsyncSpotifyClient,
  userId: string, name: string, public = true,
  collaborative = false, description = ""): Future[Playlist] {.async.} =
  var body = %* {"name": name, "public": public, "collaborative": collaborative}
  if description != "":
    body["description"] = %* description
  let
    path = buildPath(PostPlaylistPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPost)
  result = await toResponse[Playlist](response)

proc getUserPlaylists*(client: AsyncSpotifyClient,
  limit = 20, offset = 0): Future[Paging[SimplePlaylist]] {.async.} =
  let
    path = buildPath(GetUserPlaylistsPath, @[
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
  result = await toResponse[Paging[SimplePlaylist]](response)

proc getPlaylists*(client: AsyncSpotifyClient,
  userId: string, limit = 20,
  offset = 0): Future[Paging[SimplePlaylist]] {.async.} =
  let
    path = buildPath(GetPlaylistsPath.fmt, @[
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
  result = await toResponse[Paging[SimplePlaylist]](response)

proc getPlaylistCoverImage*(client: AsyncSpotifyClient,
  playlistId: string): Future[seq[Image]] {.async.} =
  let
    path = buildPath(GetPlaylistCoverImagePath.fmt, @[])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = toSeq[Image](body)

proc getPlaylist*(client: AsyncSpotifyClient,
  playlistId: string, fields, market = ""): Future[Playlist] {.async.} =
  let
    path = buildPath(GetPlaylistPath.fmt, @[
      newQuery("fields", fields),
      newQuery("market", market)
    ])
    response = await client.request(path)
  result = await toResponse[Playlist](response)

proc getPlaylistTracks*(client: AsyncSpotifyClient,
  playlistId: string, fields = "", limit = 100,
  offset = 0, market = ""): Future[Paging[PlaylistTrack]] {.async.} =
  let
    path = buildPath(GetPlaylistTracksPath.fmt, @[
      newQuery("fields", fields),
      newQuery("limit", $limit),
      newQuery("offset", $offset),
      newQuery("market", market)
    ])
    response = await client.request(path)
  result = await toResponse[Paging[PlaylistTrack]](response)

proc deleteTracksFromPlaylist*(client: AsyncSpotifyClient,
  playlistId: string, tracks: seq[string]): Future[Snapshot] {.async.} =
  var body = newJObject()
  var arr = newJArray()
  for track in tracks:
    arr.add(%* {"uri": track})
  body["tracks"] = arr
  let
    path = buildPath(DeleteTracksFromPlaylistPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpDelete)
  result = await toResponse[Snapshot](response)

proc reorderPlaylistTracks*(client: AsyncSpotifyClient,
  playlistId: string, rangeStart, insertBefore: int,
  rangeLength = 1, snapshotId = ""): Future[Snapshot] {.async.} =
  var body = %* {
    "range_start": rangeStart,
    "range_length": rangeLength,
    "insert_before": insertBefore
  }
  if snapshotId != "":
    body["snapshot_id"] = %* snapshotId
  let
    path = buildPath(ReorderPlaylistTracksPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  result = await toResponse[Snapshot](response)

proc replacePlaylistTracks*(client: AsyncSpotifyClient,
  playlistId: string, uris: seq[string]) {.async.} =
  let
    body = %* {"uris": uris}
    path = buildPath(ReplacePlaylistTracksPath.fmt, @[])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc uploadCustomPlaylistCoverImage*(client: AsyncSpotifyClient,
  playlistId, encodedData: string) {.async.} =
  let
    path = buildPath(UploadCustomPlaylistCoverImagePath.fmt, @[])
    response = await client.request(path, body = encodedData, httpMethod = HttpPut,
      extraHeaders = newHttpHeaders({"Content-Type": "image/jpeg"}))
  await response.handleError()

proc uploadCustomPlaylistCoverImageWithPath*(client: AsyncSpotifyClient,
  playlistId, jpegPath: string) {.async.} =
  await client.uploadCustomPlaylistCoverImage(playlistId,
    encode(readFile(jpegPath)))
