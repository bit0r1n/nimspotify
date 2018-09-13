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

import ospaths
import httpclient
import .. / src / artists
import .. / src / spotifyclient

const target = "0OdUWJ0sBjDrqHygGUXeCF"

let
  token = newHttpClient().authorizationCodeGrant(
    getEnv("SPOTIFY_ID"),
    getEnv("SPOTIFY_SECRET"),
    @[]
  )
  client = newSpotifyClient(token.accessToken, token.refreshToken, token.expiresIn)
  artist = client.getArtist(target)
  albums = client.getArtistAlbums(target)
  tracks = client.getArtistTopTracks(target, "DE")
  relatedArtists = client.getArtistRelatedArtists(target)
  artistsResult = client.getArtists(@[target, "0oSGxfWSnnOXhD2fKuz2Gy"])

echo artist.name
echo artist.popularity

for album in albums.items:
  echo album.name
  echo album.releaseDate

for track in tracks:
  echo track.name
  echo track.durationMs

for artist in relatedArtists:
  echo artist.name
  echo artist.popularity

for artist in artistsResult:
  echo artist.name
  echo artist.popularity