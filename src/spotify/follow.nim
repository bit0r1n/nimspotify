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
# date  : 2018-09-13

import spotifyuri, spotifyclient
import json, sequtils, strformat, httpclient, asyncdispatch
import objects / [ error, artist, spotifyresponse, cursorbasedpaging, internalunmarshallers ]

const
  IsFollowingPath = "/me/following/contains"
  IsFollowingPlaylistPath = "/users/{ownerId}/playlists/{playlistId}/followers/contains"
  FollowPath = "/me/following"
  FollowPlaylistPath = "/playlists/{playlistId}/followers"
  GetFollowedPath = "/me/following"
  UnfollowPath = "/me/following"
  UnfollowPlaylistPath = "/playlists/{playlistId}/followers"

proc internalIsFollow(client: AsyncSpotifyClient,
  followType: string, ids: seq[string]): Future[seq[bool]] {.async.} =
  let
    path = buildPath(IsFollowingPath, @[
      newQuery("type", followType),
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  let json = parseJson body
  for elem in json.elems:
    result.add elem.getBool

proc isFollowArtist*(client: AsyncSpotifyClient,
  ids: seq[string]): Future[seq[bool]] {.async.} =
  result = await client.internalIsFollow("artist", ids)

proc isFollowUser*(client: AsyncSpotifyClient,
  ids: seq[string]): Future[seq[bool]] {.async.} =
  result = await client.internalIsFollow("user", ids)

proc isFollowPlaylist*(client: AsyncSpotifyClient,
  ownerId, playlistId: string,
  ids: seq[string]): Future[seq[bool]] {.async.} =
  let
    path = buildPath(IsFollowingPlaylistPath.fmt, @[
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  let json = parseJson body
  for elem in json.elems:
    result.add elem.getBool

proc internalFollow(client: AsyncSpotifyClient,
  followType: string, ids: seq[string]) {.async.} =
  let
    path = buildPath(FollowPath, @[
      newQuery("type", followType),
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc followArtist*(client: AsyncSpotifyClient,
  ids: seq[string]) {.async.} =
  await client.internalFollow("artist", ids)

proc followUser*(client: AsyncSpotifyClient,
  ids: seq[string]) {.async.} =
  await client.internalFollow("user", ids)

proc followPlaylist*(client: AsyncSpotifyClient,
  playlistId: string, public = true) {.async.} =
  let
    path = buildPath(FollowPlaylistPath.fmt, @[])
    body = %* {"public": public}
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc getFollowedArtists*(client: AsyncSpotifyClient,
  limit = 20, after = ""): Future[CursorBasedPaging[Artist]] {.async.} =
  let
    path = buildPath(GetFollowedPath, @[
      newQuery("type", "artist"),
      newQuery("limit", $limit),
      newQuery("after", after)
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = to[CursorBasedPaging[Artist]](body, "artists")

proc internalUnfollow(client: AsyncSpotifyClient,
  followType: string, ids: seq[string]) {.async.} =
  let
    path = buildPath(UnfollowPath, @[
      newQuery("type", followType),
      newQuery("ids", ids.foldr(a & "," & b))
    ])
    response = await client.request(path, httpMethod = HttpDelete)
  await response.handleError()

proc unfollowArtist*(client: AsyncSpotifyClient,
  ids: seq[string]) {.async.} =
  await client.internalUnfollow("artist", ids)

proc unfollowUser*(client: AsyncSpotifyClient,
  ids: seq[string]) {.async.} =
  await client.internalUnfollow("user", ids)

proc unfollowPlaylist*(client: AsyncSpotifyClient,
  playlistId: string) {.async.} =
  let
    path = buildPath(UnfollowPlaylistPath.fmt, @[])
    response = await client.request(path, httpMethod = HttpDelete)
  await response.handleError()
