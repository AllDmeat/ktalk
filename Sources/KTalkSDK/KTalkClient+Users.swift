import Foundation

extension KTalkClient {
  /// The result of searching users.
  public typealias UserSearchResult =
    Components.Schemas.SkbKontur_Talk_Web_Entities_TalkUserSearchResult
  /// The result of scanning all users.
  public typealias UserScanResult = Components.Schemas
    .SkbKontur_Talk_Web_Entities_TalkUserScanResult
  /// A single user.
  public typealias User = Components.Schemas.SkbKontur_Talk_Users_Api_Models_TalkUser
  /// Parameters for creating or updating a user.
  public typealias UserParams = Components.Schemas.SkbKontur_Talk_Users_Api_Models_TalkUserParams
  /// A reference to a role assigned to a user.
  public typealias UserRoleRef =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRoleRef
  /// A request to change a user's roles.
  public typealias ChangeRolesRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserChangeRolesRequest
  /// A user's permissions.
  public typealias UserPermissions = Components.Schemas
    .SkbKontur_Talk_Web_Entities_TalkUserPermissions

  /// Searches users in the space.
  public func searchUsers(
    query: String? = nil, emails: [String]? = nil, role: String? = nil, skip: Int? = nil,
    top: Int? = nil, includeDisabled: Bool? = nil, includeGuests: Bool? = nil
  ) async throws(KTalkError) -> UserSearchResult {
    try await call {
      let output = try await client.usersGet(
        .init(
          query: .init(
            query: query, email: emails, role: role, top: top.map(Int32.init),
            skip: skip.map(Int32.init), includeDisabled: includeDisabled,
            includeGuests: includeGuests)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Scans all users in the space.
  public func scanUsers(
    offset: String? = nil, top: Int? = nil, includeDisabled: Bool? = nil,
    includeGuests: Bool? = nil, role: String? = nil
  ) async throws(KTalkError) -> UserScanResult {
    try await call {
      let output = try await client.usersScan(
        .init(
          query: .init(
            offset: offset, top: top.map(Int32.init), includeDisabled: includeDisabled,
            includeGuests: includeGuests, role: role)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Fetches a user by key.
  public func user(key: String) async throws(KTalkError) -> User {
    try await call {
      let output = try await client.usersGetUserByKey(.init(path: .init(userKey: key)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: key)
      }
    }
  }

  /// Creates, updates, or restores users.
  public func createOrUpdateUsers(_ users: [UserParams]) async throws(KTalkError)
    -> UserSearchResult
  {
    try await call {
      let output = try await client.usersCreateOrUpdate(.init(body: .json(users)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Deletes a user.
  public func deleteUser(key: String) async throws(KTalkError) {
    try await call {
      let output = try await client.usersDelete(.init(path: .init(userKey: key)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: key)
      }
    }
  }

  /// Revokes all of a user's sessions.
  public func revokeSessions(userKey: String) async throws(KTalkError) {
    try await call {
      let output = try await client.usersRevokeTokensForUser(.init(path: .init(userKey: userKey)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: userKey)
      }
    }
  }

  /// Fetches a user's roles.
  public func userRoles(userKey: String) async throws(KTalkError) -> [UserRoleRef] {
    try await call {
      let output = try await client.usersGetRoles(.init(path: .init(userKey: userKey)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: userKey)
      }
    }
  }

  /// Changes a user's roles, returning the updated roles.
  public func changeRoles(userKey: String, request: ChangeRolesRequest) async throws(KTalkError)
    -> [UserRoleRef]
  {
    try await call {
      let output = try await client.usersChangeRoles(
        .init(path: .init(userKey: userKey), body: .json(request)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: userKey)
      }
    }
  }

  /// Sets a user's permissions (blocks or restores the account).
  public func setPermissions(userKey: String, permissions: UserPermissions)
    async throws(KTalkError) -> UserSearchResult
  {
    try await call {
      let output = try await client.usersSetUserPermissions(
        .init(path: .init(userKey: userKey), body: .json(permissions)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "user", identifier: userKey)
      }
    }
  }
}
