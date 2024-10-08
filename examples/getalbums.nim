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

import os, httpclient, asyncdispatch
import ../src/spotify/[ scope, albums, spotifyclient ]

const target = "0sNOF9WDwhWunNAHPD3Baj"

let
  token = waitFor newAsyncHttpClient().authorizationCodeGrant(
    getEnv("SPOTIFY_ID"),
    getEnv("SPOTIFY_SECRET"),
    @[]
  )
  client = newAsyncSpotifyClient(token)
  album = waitFor client.getAlbum(target)
  tracks = waitFor client.getAlbumTracks(target)
  deAlbums = waitFor client.getAlbums(@[target, "53A0W3U0s8diEn9RhXQhVz"], "DE")

echo album.albumType
for artist in album.artists:
  echo artist.name
echo album.name
echo album.releaseDate

for track in tracks.items:
  echo track.name
  echo track.durationMs

for album in deAlbums:
  echo album.albumType
  echo album.name
  echo album.releaseDate
