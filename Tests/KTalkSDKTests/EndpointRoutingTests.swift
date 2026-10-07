import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import KTalkSDK

/// Each facade method reaches its own endpoint with the right method and decodes the reply.
///
/// Bodies are minimal synthetic payloads; per-field decoding is covered by the tag suites.
@Suite("Endpoint routing")
struct EndpointRoutingTests {
  private static let group =
    #"{"groupKey":"g-1","parentKey":"root","position":1,"title":"Floor 1"}"#
  private static let groupTree = #"{"groups":[],"key":"root","position":0,"title":"All"}"#
  private static let room = #"{"conferenceId":"c-1","roomName":"demo","stageConferenceId":"s-1"}"#

  /// A transport that answers 200 with `body` and records the request.
  private func replay(_ body: String? = nil, contentType: String = "application/json")
    -> ReplayTransport
  {
    ReplayTransport { _, _, _, _ in
      var headers = HTTPFields()
      if body != nil { headers[.contentType] = contentType }
      return (HTTPResponse(status: .ok, headerFields: headers), body.map { HTTPBody($0) })
    }
  }

  private func client(_ transport: ReplayTransport) throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token", transport: transport)
  }

  /// Runs `body` against a replayed reply and checks the request line it produced.
  private func expectRoute(
    _ method: HTTPRequest.Method, _ path: String, reply: String? = nil,
    contentType: String = "application/json",
    _ body: (KTalkClient) async throws -> Void
  ) async throws {
    let transport = replay(reply, contentType: contentType)
    try await body(try client(transport))
    let request = try #require(transport.lastRequest?.request)
    #expect(request.method == method)
    #expect(request.path?.components(separatedBy: "?").first == path)
  }

  // MARK: - Recordings

  @Test func listRecordingsV1() async throws {
    try await expectRoute(.get, "/api/Domain/recordings", reply: #"{"recordings":[]}"#) {
      _ = try await $0.listRecordingsV1(top: 5, orderMode: .byTimeNewFirst)
    }
  }

  @Test func recordingParticipants() async throws {
    try await expectRoute(.get, "/api/Domain/recordings/rec-1/participants", reply: "[]") {
      _ = try await $0.recordingParticipants(key: "rec-1")
    }
  }

  @Test func setAndUnsetImmutable() async throws {
    try await expectRoute(.post, "/api/Domain/recordings/rec-1/immutable") {
      try await $0.setRecordingImmutable(key: "rec-1")
    }
    try await expectRoute(.delete, "/api/Domain/recordings/rec-1/immutable") {
      try await $0.unsetRecordingImmutable(key: "rec-1")
    }
  }

  @Test func activeRecording() async throws {
    try await expectRoute(.get, "/api/Recordings/current", reply: #"{"recordingKey":"rec-1"}"#) {
      _ = try await $0.activeRecording(roomName: "demo")
    }
  }

  @Test func startRecording() async throws {
    try await expectRoute(.post, "/api/Recordings/start", reply: "{}") {
      let params = try JSONDecoder().decode(
        KTalkClient.StartRecordingParams.self, from: Data(#"{"roomName":"demo"}"#.utf8))
      _ = try await $0.startRecording(params)
    }
  }

  @Test func editAndDeleteRecording() async throws {
    try await expectRoute(.put, "/api/Recordings/rec-1") {
      let params = try JSONDecoder().decode(
        KTalkClient.RecordingUpdateParams.self, from: Data(#"{"title":"Synthetic"}"#.utf8))
      try await $0.editRecording(key: "rec-1", params: params)
    }
    try await expectRoute(.delete, "/api/Recordings/rec-1") {
      try await $0.deleteRecording(key: "rec-1", force: true)
    }
  }

  @Test func recordingAccess() async throws {
    try await expectRoute(.get, "/api/Recordings/rec-1/access", reply: #"{"userAccesses":[]}"#) {
      _ = try await $0.recordingAccess(key: "rec-1")
    }
    try await expectRoute(.patch, "/api/Recordings/rec-1/access") {
      let patch = try JSONDecoder().decode(
        KTalkClient.RecordingAccessPatch.self, from: Data(#"{"userAccesses":[]}"#.utf8))
      try await $0.updateRecordingAccess(key: "rec-1", patch: patch)
    }
  }

  @Test func summaryByTypeAndArtifacts() async throws {
    try await expectRoute(.get, "/api/recordings/rec-1/summary/protocol", reply: "{}") {
      _ = try await $0.recordingSummaryByType(key: "rec-1", type: ._protocol)
    }
    try await expectRoute(.get, "/api/recordings/v2/rec-1/summary", reply: "{}") {
      _ = try await $0.recordingArtifacts(key: "rec-1")
    }
  }

  // MARK: - Kiosks

  @Test func kioskReads() async throws {
    try await expectRoute(.get, "/api/Kiosk/count", reply: "3") {
      let value = try await $0.kioskCount(statusValues: [.active])
      #expect(value == 3)
    }
    try await expectRoute(.get, "/api/Kiosk/versions", reply: #"["1.0"]"#) {
      let value = try await $0.kioskVersions()
      #expect(value == ["1.0"])
    }
    try await expectRoute(.get, "/api/Kiosk/groups", reply: Self.groupTree) {
      _ = try await $0.kioskGroups()
    }
    try await expectRoute(
      .get, "/api/Kiosk/k-1/current-calendar-event", reply: #"{"timezone":"GMT+5"}"#
    ) {
      _ = try await $0.kioskCurrentEvent(id: "k-1")
    }
  }

  @Test func kioskGroups() async throws {
    try await expectRoute(.post, "/api/Kiosk/groups", reply: Self.group) {
      let request = try JSONDecoder().decode(
        KTalkClient.KioskCreateGroupRequest.self, from: Data(#"{"name":"Floor 1"}"#.utf8))
      _ = try await $0.createKioskGroup(request)
    }
    try await expectRoute(.patch, "/api/Kiosk/groups/g-1", reply: Self.group) {
      let request = try JSONDecoder().decode(
        KTalkClient.KioskUpdateGroupRequest.self, from: Data("{}".utf8))
      _ = try await $0.updateKioskGroup(key: "g-1", request: request)
    }
    try await expectRoute(.delete, "/api/Kiosk/groups/g-1") {
      try await $0.deleteKioskGroup(key: "g-1")
    }
  }

  @Test func kioskActions() async throws {
    try await expectRoute(.put, "/api/Kiosk/k-1/block") { try await $0.blockKiosk(id: "k-1") }
    try await expectRoute(.put, "/api/Kiosk/k-1/unblock") { try await $0.unblockKiosk(id: "k-1") }
    try await expectRoute(.post, "/api/Kiosk/k-1/equipment-check") {
      try await $0.checkKioskEquipment(id: "k-1")
    }
    try await expectRoute(.post, "/api/Kiosk/move") {
      try await $0.moveKiosks(
        try JSONDecoder().decode(
          KTalkClient.KioskMoveRequest.self, from: Data(#"{"groupKey":"g-1","kioskIds":[]}"#.utf8)))
    }
    try await expectRoute(.post, "/api/Kiosk/mass-update") {
      try await $0.massUpdateKiosks(
        try JSONDecoder().decode(
          KTalkClient.KioskMassUpdateRequest.self,
          from: Data(#"{"kioskIds":[],"parameters":{}}"#.utf8)))
    }
    let unit = try JSONDecoder().decode(
      KTalkClient.KioskNotificationUnit.self, from: Data("{}".utf8))
    try await expectRoute(.post, "/api/Kiosk/operations/add-notification-unit") {
      try await $0.addKioskNotificationUnit(unit)
    }
    try await expectRoute(.post, "/api/Kiosk/operations/remove-notification-unit") {
      try await $0.removeKioskNotificationUnit(unit)
    }
  }

  @Test func kioskArtwork() async throws {
    let file = KTalkClient.UploadFile(filename: "a.png", data: Data("synthetic".utf8))
    try await expectRoute(.post, "/api/Kiosk/screensavers", reply: "{}") {
      _ = try await $0.uploadKioskScreensavers([file])
    }
    try await expectRoute(.delete, "/api/Kiosk/screensavers/s-1", reply: "{}") {
      _ = try await $0.deleteKioskScreensaver(key: "s-1")
    }
    try await expectRoute(.post, "/api/Kiosk/wallpapers", reply: "{}") {
      _ = try await $0.uploadKioskWallpapers([file])
    }
    try await expectRoute(.delete, "/api/Kiosk/wallpapers/w-1", reply: "{}") {
      _ = try await $0.deleteKioskWallpaper(key: "w-1")
    }
    try await expectRoute(.post, "/api/Kiosk/wallpapers/default") {
      try await $0.setDefaultKioskWallpapers(
        try JSONDecoder().decode(KTalkClient.KioskWallpaperSettings.self, from: Data("{}".utf8)))
    }
  }

  @Test func uploadSendsMultipartWithFilename() async throws {
    let transport = replay("{}")
    _ = try await client(transport).uploadKioskWallpapers([
      KTalkClient.UploadFile(filename: "wall.png", data: Data("synthetic".utf8))
    ])
    let recorded = try #require(transport.lastRequest)
    #expect(recorded.request.headerFields[.contentType]?.hasPrefix("multipart/form-data") == true)
    let sent = try await String(collecting: try #require(recorded.body), upTo: .max)
    #expect(sent.contains(#"name="wallpaper""#))
    #expect(sent.contains(#"filename="wall.png""#))
    #expect(sent.contains("synthetic"))
  }

  // MARK: - Roles, users, rooms

  @Test func defaultRoles() async throws {
    let change = try JSONDecoder().decode(
      KTalkClient.ChangeDefaultRoleRequest.self, from: Data("{}".utf8))
    try await expectRoute(.get, "/api/roles/default", reply: "{}") {
      _ = try await $0.defaultRole()
    }
    try await expectRoute(.post, "/api/roles/default", reply: "{}") {
      _ = try await $0.changeDefaultRole(change)
    }
    try await expectRoute(.get, "/api/roles/defaults/guest", reply: "{}") {
      _ = try await $0.defaultRoleByType(.guest)
    }
    try await expectRoute(.post, "/api/roles/defaults/guest", reply: "{}") {
      _ = try await $0.changeDefaultRoleByType(.guest, request: change)
    }
  }

  @Test func avatars() async throws {
    let file = KTalkClient.UploadFile(filename: "me.png", data: Data("synthetic".utf8))
    try await expectRoute(.post, "/api/Users/u-1/avatar", reply: "{}") {
      _ = try await $0.uploadAvatar(userKey: "u-1", file: file)
    }
    try await expectRoute(.delete, "/api/Users/u-1/avatar") {
      try await $0.deleteAvatar(userKey: "u-1")
    }
    try await expectRoute(.post, "/api/Users/u-1/avatar/sync") {
      try await $0.syncAvatar(userKey: "u-1")
    }
  }

  @Test func roomCalls() async throws {
    try await expectRoute(.put, "/api/Rooms/demo/anonymousAccess", reply: Self.room) {
      _ = try await $0.setAnonymousAccess(
        roomName: "demo",
        request: try JSONDecoder().decode(
          KTalkClient.AnonymousAccessRequest.self, from: Data("{}".utf8)))
    }
    try await expectRoute(.post, "/api/Rooms/demo/notifyCall", reply: "{}") {
      _ = try await $0.notifyCall(
        roomName: "demo",
        params: try JSONDecoder().decode(
          KTalkClient.NotifyCallParams.self, from: Data(#"{"callees":[]}"#.utf8)))
    }
    try await expectRoute(.post, "/api/Rooms/demo/cancelCall") {
      try await $0.cancelCall(
        roomName: "demo",
        params: try JSONDecoder().decode(KTalkClient.CancelCallParams.self, from: Data("{}".utf8)))
    }
  }

  // MARK: - Files and telemetry

  @Test func fileDownloadsReturnBytes() async throws {
    let octet = "application/octet-stream"
    try await expectRoute(
      .get, "/api/ConferenceReports/c-1/questions", reply: "xlsx", contentType: octet
    ) {
      let value = try await $0.conferenceQuestionsReport(key: "c-1")
      #expect(value == Data("xlsx".utf8))
    }
    try await expectRoute(.get, "/api/RoomReport/statistics", reply: "xlsx", contentType: octet) {
      let value = try await $0.attendanceReport(from: Date(timeIntervalSince1970: 0))
      #expect(value == Data("xlsx".utf8))
    }
    try await expectRoute(
      .get, "/api/DeepFakeDetector/conference/c-1/task/t-1/file", reply: "wav", contentType: octet
    ) {
      let value = try await $0.deepFakeTaskFile(conferenceKey: "c-1", taskKey: "t-1")
      #expect(value == Data("wav".utf8))
    }
    try await expectRoute(
      .get, "/api/DeepFakeDetector/conference/c-1/tasks/files", reply: "zip", contentType: octet
    ) {
      let value = try await $0.deepFakeTaskFiles(conferenceKey: "c-1")
      #expect(value == Data("zip".utf8))
    }
  }

  @Test func telemetry() async throws {
    try await expectRoute(.get, "/api/ClientsTelemetry/v2", reply: #"{"telemetry":[]}"#) {
      _ = try await $0.telemetry(take: 10)
    }
    try await expectRoute(.get, "/api/ClientsTelemetry", reply: #"{"telemetry":[]}"#) {
      _ = try await $0.telemetryV1(take: 10)
    }
  }

  @Test("calendar servers map a documented 403 to forbidden, not 400")
  func calendarForbidden() async throws {
    let client = try client(ReplayTransport.returning(statusCode: 403))
    let error = await #expect(throws: KTalkError.self) { _ = try await client.calendarServers() }
    guard case .forbidden = error else {
      Issue.record("expected .forbidden, got \(String(describing: error))")
      return
    }
  }
}
