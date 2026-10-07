import Foundation
import OpenAPIRuntime

extension KTalkClient {
  /// A list of kiosks.
  public typealias KioskList = Components.Schemas
    .SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskList
  /// A kiosk (daemon).
  public typealias Kiosk = Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskDaemon
  /// Parameters for creating a kiosk.
  public typealias KioskCreateParams =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskDaemonCreateParameters
  /// Parameters for updating a kiosk.
  public typealias KioskUpdateParams =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskDaemonUpdateParameters
  /// A kiosk search result.
  public typealias KioskSearchResult =
    Components.Schemas
    .SkbKontur_Talk_Kiosk_Api_SearchResultSkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskDaemon
  /// Information about a kiosk gadget.
  public typealias KioskGadget =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Gadget_TalkKioskGadgetInfo
  /// Kiosk news / support requests.
  public typealias KioskNews = Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_News_TalkKioskNews
  /// The domain's kiosk screensavers.
  public typealias KioskScreensavers =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Screensaver_TalkKioskRichScreensaverResponse
  /// The domain's kiosk wallpapers.
  public typealias KioskWallpapers =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Wallpaper_TalkKioskRichWallpaperResponse

  /// A kiosk lifecycle status.
  public typealias KioskStatus = Components.Schemas.SkbKontur_Talk_Kiosk_Domain_KioskDaemonStatus
  /// The tree of kiosk groups.
  public typealias KioskGroupTree =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Group_TalkKioskGroupTree
  /// A kiosk group.
  public typealias KioskGroup = Components.Schemas
    .SkbKontur_Talk_Kiosk_Api_Models_Group_TalkKioskGroup
  /// A request to create a kiosk group.
  public typealias KioskCreateGroupRequest =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Group_TalkKioskCreateGroupRequest
  /// A request to update a kiosk group.
  public typealias KioskUpdateGroupRequest =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Group_TalkKioskUpdateGroupRequest
  /// Settings applied to many kiosks at once.
  public typealias KioskMassUpdateRequest =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKioskMassUpdateRequest
  /// A request to move kiosks into a group.
  public typealias KioskMoveRequest =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Kiosk_TalkKiosksMoveToGroupRequest
  /// A subscriber to kiosk and gadget status notifications.
  public typealias KioskNotificationUnit =
    Components.Schemas.SkbKontur_Talk_Platform_UserDomains_Domain_KioskNotificationUnit
  /// The result of uploading kiosk screensavers.
  public typealias KioskScreensaverUpload =
    Components.Schemas
    .SkbKontur_Talk_Kiosk_Api_Models_Screensaver_TalkKioskUploadScreensaverResponse
  /// The screensavers left after a deletion.
  public typealias KioskScreensaverList =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Screensaver_TalkKioskScreensaversResponse
  /// The result of uploading kiosk wallpapers.
  public typealias KioskWallpaperUpload =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Wallpaper_TalkKioskUploadWallpaperResponse
  /// The wallpapers left after a deletion.
  public typealias KioskWallpaperList =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Wallpaper_TalkKioskWallpapersResponse
  /// The wallpapers a kiosk shows by default.
  public typealias KioskWallpaperSettings =
    Components.Schemas.SkbKontur_Talk_Kiosk_Api_Models_Wallpaper_TalkKioskWallpaperSettingsRequest

  /// Lists the kiosks in the space.
  public func listKiosks() async throws(KTalkError) -> KioskList {
    try await call {
      switch try await client.kioskGet(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches a kiosk by id.
  public func kiosk(id: String) async throws(KTalkError) -> Kiosk {
    try await call {
      switch try await client.kioskGet2(.init(path: .init(kioskId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Creates a kiosk.
  public func createKiosk(_ params: KioskCreateParams) async throws(KTalkError) -> Kiosk {
    try await call {
      switch try await client.kioskCreate(.init(body: .json(params))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Updates a kiosk.
  public func updateKiosk(id: String, params: KioskUpdateParams) async throws(KTalkError) -> Kiosk {
    try await call {
      switch try await client.kioskUpdate(
        .init(path: .init(kioskId: id), body: .json(params)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Deletes a kiosk.
  public func deleteKiosk(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.kioskDelete(.init(path: .init(kioskId: id))) {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Searches kiosks by parameters.
  public func searchKiosks() async throws(KTalkError) -> KioskSearchResult {
    try await call {
      switch try await client.kioskSearch(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the available kiosk gadgets.
  public func kioskGadgets() async throws(KTalkError) -> [KioskGadget] {
    try await call {
      switch try await client.kioskGetGadgets(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches kiosk news / support requests.
  public func kioskNews() async throws(KTalkError) -> KioskNews {
    try await call {
      switch try await client.kioskGetKioskNews(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the domain's kiosk screensavers.
  public func kioskScreensavers() async throws(KTalkError) -> KioskScreensavers {
    try await call {
      switch try await client.kioskGetDomainScreensavers(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the domain's kiosk wallpapers.
  public func kioskWallpapers() async throws(KTalkError) -> KioskWallpapers {
    try await call {
      switch try await client.kioskGetDomainWallpapers(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Counts the kiosks that match the filters.
  public func kioskCount(
    complexSearch: String? = nil, status: String? = nil, statusValues: [KioskStatus]? = nil,
    version: String? = nil, offset: Int? = nil, pageSize: Int? = nil, groupKey: String? = nil
  ) async throws(KTalkError) -> Int {
    try await call {
      switch try await client.kioskCount(
        .init(
          query: .init(
            complexSearch: complexSearch, status: status, statusValue: statusValues,
            version: version, offset: offset.map(Int32.init), pageSize: pageSize.map(Int32.init),
            groupKey: groupKey)))
      {
      case .ok(let ok): return Int(try ok.body.json)
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Lists the app versions installed on the kiosks.
  public func kioskVersions() async throws(KTalkError) -> [String] {
    try await call {
      switch try await client.kioskGetUniqueVersions(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches the tree of kiosk groups.
  public func kioskGroups() async throws(KTalkError) -> KioskGroupTree {
    try await call {
      switch try await client.kioskGetGroups(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Creates a kiosk group.
  public func createKioskGroup(_ request: KioskCreateGroupRequest) async throws(KTalkError)
    -> KioskGroup
  {
    try await call {
      switch try await client.kioskCreateGroup(.init(body: .json(request))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Updates a kiosk group.
  public func updateKioskGroup(key: String, request: KioskUpdateGroupRequest)
    async throws(KTalkError) -> KioskGroup
  {
    try await call {
      switch try await client.kioskUpdateGroup(
        .init(path: .init(groupKey: key), body: .json(request)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "kiosk group", identifier: key)
      }
    }
  }

  /// Deletes a kiosk group.
  public func deleteKioskGroup(key: String) async throws(KTalkError) {
    try await call {
      switch try await client.kioskDeleteGroup(.init(path: .init(groupKey: key))) {
      case .ok: return
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "kiosk group", identifier: key)
      }
    }
  }

  /// Moves kiosks into a group.
  public func moveKiosks(_ request: KioskMoveRequest) async throws(KTalkError) {
    try await call {
      switch try await client.kioskKiosksMoveToGroup(.init(body: .json(request))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Applies settings to many kiosks at once.
  public func massUpdateKiosks(_ request: KioskMassUpdateRequest) async throws(KTalkError) {
    try await call {
      switch try await client.kioskMassUpdate(.init(body: .json(request))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Subscribes a user to status notifications for every kiosk and gadget.
  public func addKioskNotificationUnit(_ unit: KioskNotificationUnit) async throws(KTalkError) {
    try await call {
      switch try await client.kioskAddNotificationUnitToAllKiosks(.init(body: .json(unit))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Removes a user's status-notification subscription from every kiosk and gadget.
  public func removeKioskNotificationUnit(_ unit: KioskNotificationUnit) async throws(KTalkError) {
    try await call {
      switch try await client.kioskRemoveNotificationUnitToAllKiosks(.init(body: .json(unit))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Blocks a kiosk.
  public func blockKiosk(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.kioskBlock(.init(path: .init(kioskId: id))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Unblocks a kiosk.
  public func unblockKiosk(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.kioskUnblock(.init(path: .init(kioskId: id))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Starts an equipment check on a kiosk.
  public func checkKioskEquipment(id: String) async throws(KTalkError) {
    try await call {
      switch try await client.kioskEquipmentCheck(.init(path: .init(kioskId: id))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Fetches the event currently running in a kiosk's calendar.
  public func kioskCurrentEvent(id: String) async throws(KTalkError) -> Meeting {
    try await call {
      switch try await client.kioskGetCurrentCalendarEvent(.init(path: .init(kioskId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "kiosk", identifier: id)
      }
    }
  }

  /// Uploads kiosk screensavers.
  public func uploadKioskScreensavers(_ files: [UploadFile]) async throws(KTalkError)
    -> KioskScreensaverUpload
  {
    try await call {
      let parts: [Operations.KioskUploadScreensavers.Input.Body.MultipartFormPayload] = files.map {
        .screensaver(.init(payload: .init(body: HTTPBody($0.data)), filename: $0.filename))
      }
      switch try await client.kioskUploadScreensavers(.init(body: .multipartForm(.init(parts)))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Deletes a kiosk screensaver.
  public func deleteKioskScreensaver(key: String) async throws(KTalkError) -> KioskScreensaverList {
    try await call {
      switch try await client.kioskDeleteScreensaver(.init(path: .init(key: key))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "screensaver", identifier: key)
      }
    }
  }

  /// Uploads kiosk wallpapers.
  public func uploadKioskWallpapers(_ files: [UploadFile]) async throws(KTalkError)
    -> KioskWallpaperUpload
  {
    try await call {
      let parts: [Operations.KioskUploadWallpapers.Input.Body.MultipartFormPayload] = files.map {
        .wallpaper(.init(payload: .init(body: HTTPBody($0.data)), filename: $0.filename))
      }
      switch try await client.kioskUploadWallpapers(.init(body: .multipartForm(.init(parts)))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Deletes a kiosk wallpaper.
  public func deleteKioskWallpaper(key: String) async throws(KTalkError) -> KioskWallpaperList {
    try await call {
      switch try await client.kioskDeleteWallpaper(.init(path: .init(key: key))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "wallpaper", identifier: key)
      }
    }
  }

  /// Chooses the wallpapers kiosks show by default.
  public func setDefaultKioskWallpapers(_ settings: KioskWallpaperSettings)
    async throws(KTalkError)
  {
    try await call {
      switch try await client.kioskSetDefaultWallpapers(.init(body: .json(settings))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }
}
