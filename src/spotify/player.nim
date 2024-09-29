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
# date  : 2018-09-16

import spotifyuri, spotifyclient
import json, httpclient, asyncdispatch
import objects / [ error, device, playhistory, spotifyresponse, jsonunmarshaller, internalunmarshallers, currentlyplayingtrack, currentlyplayingcontext ]

const
  GetUserDevicesPath = "/me/player/devices"
  GetUserCurrentlyPlayingContextPath = "/me/player"
  GetUserRecentlyPlayedTracksPath = "/me/player/recently-played"
  GetUserCurrentlyPlayingTrackPath = "/me/player/currently-playing"
  PausePath = "/me/player/pause"
  SeekPath = "/me/player/seek"
  SetRepeatPath = "/me/player/repeat"
  SetVolumePath = "/me/player/volume"
  NextPath = "/me/player/next"
  PreviousPath = "/me/player/previous"
  PlayPath = "/me/player/play"
  ShufflePath = "/me/player/shuffle"
  TransferPlaybackPath = "/me/player"

proc getUserDevices*(client: AsyncSpotifyClient
  ): Future[seq[Device]] {.async.} =
  let
    response = await client.request(GetUserDevicesPath)
    body = await response.body
    code = response.code
    unmarshaller = newJsonUnmarshaller(deviceReplaceTargets)

  await response.handleError()
  result = toSeq[Device](unmarshaller, body, "devices")

proc getUserCurrentlyPlayingContext*(client: AsyncSpotifyClient,
  market = ""): Future[CurrentlyPlayingContext] {.async.} =
  let
    path = buildPath(GetUserCurrentlyPlayingContextPath, @[newQuery("market", market)])
    response = await client.request(path)
    unmarshaller = newJsonUnmarshaller(deviceReplaceTargets)
  result = await toResponse[CurrentlyPlayingContext](unmarshaller, response)

proc getUserRecentlyPlayedTracks*(client: AsyncSpotifyClient,
  limit = 20, after, before = 0): Future[PlayHistory] {.async.} =
  var queries = @[newQuery("limit", $limit)]
  if after > 0:
    queries.add(newQuery("after", $after))
  if before > 0:
    queries.add(newQuery("after", $before))
  let
    path = buildPath(GetUserRecentlyPlayedTracksPath, queries)
    response = await client.request(path)
  result = await toResponse[PlayHistory](response)

proc getUserCurrentlyPlayingTrack*(client: AsyncSpotifyClient,
  market = ""): Future[CurrentlyPlayingTrack] {.async.} =
  let
    path = buildPath(GetUserCurrentlyPlayingTrackPath, @[newQuery("market", market)])
    response = await client.request(path)
  result = await toResponse[CurrentlyPlayingTrack](response)

proc pause*(client: AsyncSpotifyClient,
  deviceId = "") {.async.} =
  let
    path = buildPath(PausePath, @[newQuery("device_id", deviceId)])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc seek*(client: AsyncSpotifyClient,
  positionMs: int, deviceId = "") {.async.} =
  let
    path = buildPath(SeekPath, @[
      newQuery("position_ms", $positionMs),
      newQuery("device_id", deviceId)
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc setRepeat*(client: AsyncSpotifyClient,
  state: RepeatState, deviceId = "") {.async.} =
  let
    path = buildPath(SetRepeatPath, @[
      newQuery("state", $state),
      newQuery("device_id", deviceId)
    ])
    response = await client.request(path, httpMethod = HttpPut)
    body = await response.body
  await response.handleError()

proc setVolume*(client: AsyncSpotifyClient,
  volumePercent: int, deviceId = "") {.async.} =
  let
    path = buildPath(SetVolumePath, @[
      newQuery("volume_percent", $volumePercent),
      newQuery("device_id", deviceId)
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc next*(client: AsyncSpotifyClient,
  deviceId = "") {.async.} =
  let
    path = buildPath(NextPath, @[newQuery("device_id", deviceId)])
    response =await client.request(path, httpMethod = HttpPost)
  await response.handleError()

proc previous*(client: AsyncSpotifyClient,
  deviceId = "") {.async.} =
  let
    path = buildPath(PreviousPath, @[newQuery("device_id", deviceId)])
    response = await client.request(path, httpMethod = HttpPost)
  await response.handleError()

proc buildPlayBody(contextUri: string, uris: seq[string], positionMs: int): JsonNode =
  result = newJObject()
  if contextUri != "":
    result["context_uri"] = %* contextUri
  if uris.len > 0:
    result["uris"] = %* uris
  if positionMs >= 0:
    result["position_ms"] = %* positionMs

proc internalPlay(client: AsyncSpotifyClient,
  deviceId: string, body: JsonNode) {.async.} =
  let
    path = buildPath(PlayPath, @[newQuery("device_id", deviceId)])
    response = await client.request(path, body = $body, httpMethod = HttpPut)
  await response.handleError()

proc play*(client: AsyncSpotifyClient,
  deviceId, contextUri = "", uris: seq[string] = @[],
  positionMs = -1) {.async.} =
  await client.internalPlay(deviceId, buildPlayBody(contextUri, uris, positionMs))

proc play*(client: AsyncSpotifyClient,
  offsetPosition: int, deviceId, contextUri = "", uris: seq[string] = @[],
  positionMs = -1) {.async.} =
  var body = buildPlayBody(contextUri, uris, positionMs)
  body["offset"] = %* {"position": offsetPosition}
  await client.internalPlay(deviceId, body)

proc play*(client: AsyncSpotifyClient,
  offsetUri: string, deviceId, contextUri = "", uris: seq[string] = @[],
  positionMs = -1) {.async.} =
  var body = buildPlayBody(contextUri, uris, positionMs)
  body["offset"] = %* {"uri": offsetUri}
  await client.internalPlay(deviceId, body)

proc shuffle*(client: AsyncSpotifyClient,
  shuffle: bool, deviceId = "") {.async.} =
  let
    path = buildPath(ShufflePath, @[
      newQuery("state", $shuffle),
      newQuery("device_id", deviceId)
    ])
    response = await client.request(path, httpMethod = HttpPut)
  await response.handleError()

proc transferPlayback*(client: AsyncSpotifyClient,
  deviceIds: seq[string], play = false) {.async.} =
  let
    body = %* {"device_ids": deviceIds, "play": play}
    response = await client.request(TransferPlaybackPath,
      body = $body, httpMethod = HttpPut)
  await response.handleError()
