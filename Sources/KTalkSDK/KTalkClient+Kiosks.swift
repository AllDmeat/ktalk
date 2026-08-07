import Foundation

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
}
