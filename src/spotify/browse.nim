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
# date  : 2018-09-12

import spotifyuri, spotifyclient
import sequtils, strformat, httpclient, asyncdispatch
import objects / [ error, paging, category, simplealbum, simpleplaylist, spotifyresponse, recommendations, jsonunmarshaller, featuredplaylists, recommendationseed, internalunmarshallers ]

const
  GetCategoryPath = "/browse/categories/{id}"
  GetCategoryPlaylistsPath = "/browse/categories/{id}/playlists"
  GetCategoriesPath = "/browse/categories"
  GetFeaturedPlaylistsPath = "/browse/featured-playlists"
  GetNewReleasesPath = "/browse/new-releases"
  GetRecommendationsPath = "/recommendations"

proc getCategory*(client: AsyncSpotifyClient,
  id: string, country, locale = ""): Future[Category] {.async.} =
  let
    path = buildPath(GetCategoryPath.fmt, @[
      newQuery("country", country),
      newQuery("locale", locale),
    ])
    response = await client.request(path)
  result = await toResponse[Category](response)

proc getCategoryPlaylists*(client: AsyncSpotifyClient,
  id: string, country = "",
  limit = 20, offset = 0): Future[Paging[SimplePlaylist]] {.async.} =
  let
    path = buildPath(GetCategoryPlaylistsPath.fmt, @[
      newQuery("country", country),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = to[Paging[SimplePlaylist]](body, "playlists")

proc getCategories*(client: AsyncSpotifyClient,
  country, locale = "", limit = 20,
  offset = 0): Future[Paging[Category]] {.async.} =
  let
    path = buildPath(GetCategoriesPath, @[
      newQuery("country", country),
      newQuery("locale", locale),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = to[Paging[Category]](body, "categories")

proc getFeaturedPlaylists*(client: AsyncSpotifyClient,
  country, locale, timestamp = "", limit = 20,
  offset = 0): Future[FeaturedPlaylists] {.async.} =
  let
    path = buildPath(GetFeaturedPlaylistsPath, @[
      newQuery("locale", locale),
      newQuery("country", country),
      newQuery("timestamp", timestamp),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
  result = await toResponse[FeaturedPlaylists](response)

proc getNewReleases*(client: AsyncSpotifyClient,
  country = "", limit = 20,
  offset = 0): Future[Paging[SimpleAlbum]] {.async.} =
  let
    path = buildPath(GetNewReleasesPath, @[
      newQuery("country", country),
      newQuery("limit", $limit),
      newQuery("offset", $offset)
    ])
    response = await client.request(path)
    body = await response.body
    code = response.code

  await response.handleError()
  result = to[Paging[SimpleAlbum]](body, "albums")

proc getRecommendations*(client: AsyncSpotifyClient,
  limit = 20, market = "",
  seedArtists, seedGenres, seedTracks: seq[string] = @[],
  additionalQueries: seq[Query] = @[]): Future[Recommendations] {.async.} =
  var queries = concat(@[
    newQuery("limit", $limit),
    newQuery("market", market)
  ], additionalQueries)
  if seedArtists.len > 0:
    queries.add(newQuery("seed_artists",
      seedArtists.foldr(a & "," & b)))
  if seedGenres.len > 0:
    queries.add(newQuery("seed_genres",
      seedGenres.foldr(a & "," & b)))
  if seedTracks.len > 0:
    queries.add(newQuery("seed_tracks",
      seedTracks.foldr(a & "," & b)))
  let
    path = buildPath(GetRecommendationsPath, queries)
    response = await client.request(path)
    unmarshaller = newJsonUnmarshaller(recommendationSeedReplaceTargets)
  result = await toResponse[Recommendations](unmarshaller, response)
