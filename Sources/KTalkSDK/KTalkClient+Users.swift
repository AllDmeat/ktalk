import Foundation
import OpenAPIRuntime

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
  /// The result of uploading a user's avatar.
  public typealias AvatarUploadResult =
    Components.Schemas.SkbKontur_Talk_Web_Services_TalkUserProfileUpdateResult
  /// The profile of the key's user.
  public typealias UserProfile = Components.Schemas.SkbKontur_Talk_Web_Entities_User_TalkUserProfile
  /// Changes to the profile of the key's user.
  public typealias ProfileParams = Components.Schemas
    .SkbKontur_Talk_Users_Api_Models_TalkCurrentUserParams
  /// Options for deleting the key's user or logging them out.
  public typealias DeleteSelfParams = Components.Schemas
    .SkbKontur_Talk_Web_Entities_TalkUserDeleteSelfParams
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
            query: query, email: emails, role: role, top: top.map { Int32(clamping: $0) },
            skip: skip.map { Int32(clamping: $0) }, includeDisabled: includeDisabled,
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
            offset: offset, top: top.map { Int32(clamping: $0) }, includeDisabled: includeDisabled,
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

  /// Uploads a user's avatar.
  public func uploadAvatar(userKey: String, file: UploadFile) async throws(KTalkError)
    -> AvatarUploadResult
  {
    try await call {
      let parts: [Operations.UsersUploadAvatar2.Input.Body.MultipartFormPayload] = [
        .undocumented(file.multipartPart(name: "avatar"))
      ]
      switch try await client.usersUploadAvatar2(
        .init(path: .init(userKey: userKey), body: .multipartForm(.init(parts))))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }

  /// Deletes a user's avatar.
  public func deleteAvatar(userKey: String) async throws(KTalkError) {
    try await call {
      switch try await client.usersDeleteAvatar2(.init(path: .init(userKey: userKey))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }

  /// Re-syncs a user's avatar from the identity provider.
  public func syncAvatar(userKey: String) async throws(KTalkError) {
    try await call {
      switch try await client.usersSyncAvatar(.init(path: .init(userKey: userKey))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }

  /// Fetches the profile of the key's user.
  public func profile() async throws(KTalkError) -> UserProfile {
    try await call {
      switch try await client.usersGetProfile() {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Updates the profile of the key's user.
  public func updateProfile(_ params: ProfileParams) async throws(KTalkError) {
    try await call {
      switch try await client.usersModifyUser(.init(body: .json(params))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Deletes the key's user. The key stops working.
  public func deleteSelf(_ params: DeleteSelfParams) async throws(KTalkError) {
    try await call {
      switch try await client.usersDeleteSelf(.init(body: .json(params))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Restores a user who deleted themselves.
  public func unlockSelfDeleted(userKey: String) async throws(KTalkError) {
    try await call {
      switch try await client.usersUnlockSelfDeleted(.init(path: .init(userKey: userKey))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }

  /// Ends the sessions of the key's user.
  public func logOut(_ params: DeleteSelfParams) async throws(KTalkError) {
    try await call {
      switch try await client.usersLogOut(.init(body: .json(params))) {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Uploads the avatar of the key's user.
  public func uploadOwnAvatar(file: UploadFile) async throws(KTalkError) -> AvatarUploadResult {
    try await call {
      let parts: [Operations.UsersUploadAvatar.Input.Body.MultipartFormPayload] = [
        .undocumented(file.multipartPart(name: "avatar"))
      ]
      switch try await client.usersUploadAvatar(.init(body: .multipartForm(.init(parts)))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Deletes the avatar of the key's user.
  public func deleteOwnAvatar() async throws(KTalkError) {
    try await call {
      switch try await client.usersDeleteAvatar() {
      case .ok: return
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Gives a user a role.
  public func addRole(userKey: String, role: String) async throws(KTalkError) {
    try await call {
      switch try await client.usersSetRole(.init(path: .init(userKey: userKey, role: role))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }

  /// Takes a role from a user.
  public func removeRole(userKey: String, role: String) async throws(KTalkError) {
    try await call {
      switch try await client.usersRemoveRole(.init(path: .init(userKey: userKey, role: role))) {
      case .ok: return
      case .undocumented(let s, _): throw notFoundOrStatus(s, resource: "user", identifier: userKey)
      }
    }
  }
}
