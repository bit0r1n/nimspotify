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
import sequtils, strformat, httpclient, asyncdispatch
import objects / [ track, error, audiofeature, audioanalysis, spotifyresponse, internalunmarshallers ]

const
  GetAudioAnalysisPath = "/audio-analysis/{id}"
  GetAudioFeaturePath = "/audio-features/{id}"
  GetAudioFeaturesPath = "/audio-features"
  GetTrackPath = "/tracks/{id}"
  GetTracksPath = "/tracks"

proc getAudioAnalysis*(client: AsyncSpotifyClient,
  id: string): Future[AudioAnalysis] {.async.} =
  let
    path = buildPath(GetAudioAnalysisPath.fmt, @[])
    response = await client.request(path)
    body = await response.body
  result = await toResponse[AudioAnalysis](response)

proc getAudioFeature*(client: AsyncSpotifyClient,
  id: string): Future[AudioFeature] {.async.} =
  let
    path = buildPath(GetAudioFeaturePath.fmt, @[])
    response = await client.request(path)
  result = await toResponse[AudioFeature](response)

proc getAudioFeatures*(client: AsyncSpotifyClient,
  ids: seq[string]): Future[seq[AudioFeature]] {.async.} =
  let
    path = buildPath(GetAudioFeaturesPath, @[
      newQuery("ids", ids.foldr(a & "," & b)),
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = toSeq[AudioFeature](body, "audio_features")

proc getTrack*(client: AsyncSpotifyClient,
  id: string, market = ""): Future[Track] {.async.} =
  let
    path = buildPath(GetTrackPath.fmt, @[])
    response = await client.request(path)
  result = await toResponse[Track](response)

proc getTracks*(client: AsyncSpotifyClient,
  ids: seq[string], market = ""): Future[seq[Track]] {.async.} =
  let
    path = buildPath(GetTracksPath, @[
      newQuery("ids", ids.foldr(a & "," & b)),
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = toSeq[Track](body, "tracks")
