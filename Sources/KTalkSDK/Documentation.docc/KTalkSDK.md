# ``KTalkSDK``

A typed Swift client for the Kontur.Talk integrator HTTP API.

## Overview

`KTalkSDK` wraps a `swift-openapi-generator` core with an ergonomic facade: authentication,
retries, rate-limit handling, cursor pagination, and typed errors. Create a ``KTalkClient`` for
a single space, then call the per-tag methods.

```swift
import KTalkSDK

let client = try KTalkClient(
  baseURL: "https://example.ktalk.ru",
  token: myToken
)

let page = try await client.listRecordings(limit: 20)
for recording in page.items {
  print(recording.key ?? "", recording.title ?? "")
}
```

Authentication uses an admin-issued API key sent in the `X-Auth-Token` header. All failures
surface as ``KTalkError``.

## Topics

### Essentials

- ``KTalkClient``
- ``KTalkError``
- ``Page``

### Recordings

- ``KTalkClient/listRecordings(pageToken:limit:query:)``
- ``KTalkClient/recording(key:)``
- ``KTalkClient/recordingTranscript(key:)``
- ``KTalkClient/recordingSummary(key:)``
- ``KTalkClient/downloadRecording(key:quality:)``

### Rooms

- ``KTalkClient/room(name:)``
- ``KTalkClient/updateRoom(name:params:)``
- ``KTalkClient/endConference(roomName:)``
- ``KTalkClient/setRoomLock(roomName:request:)``
- ``KTalkClient/addModerator(roomName:userRef:)``
- ``KTalkClient/removeModerator(roomName:userRef:)``
