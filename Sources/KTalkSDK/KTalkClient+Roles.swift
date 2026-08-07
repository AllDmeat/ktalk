import Foundation

extension KTalkClient {
  /// Summary information about a role.
  public typealias RoleInfo = Components.Schemas
    .SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRoleInfo
  /// A role with its permissions.
  public typealias Role = Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRole
  /// A role description returned by create/update.
  public typealias RoleDescription =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRoleDescription
  /// A request to create a role.
  public typealias RoleCreateRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRoleCreateRequest
  /// A request to update a role.
  public typealias RoleUpdateRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkUserRoleUpdateRequest
  /// The permissions available for a product.
  public typealias ProductPermissions =
    Components.Schemas.SkbKontur_Talk_Web_Entities_UserRoles_TalkProductPermissions

  /// Lists all roles in the space.
  public func listRoles() async throws(KTalkError) -> [RoleInfo] {
    try await call {
      let output = try await client.userRolesGetAllRoles(.init())
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Fetches a role by id.
  public func role(id: String) async throws(KTalkError) -> Role {
    try await call {
      let output = try await client.userRolesGetRole(.init(path: .init(roleId: id)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "role", identifier: id)
      }
    }
  }

  /// Creates a custom role.
  public func createRole(_ request: RoleCreateRequest) async throws(KTalkError) -> RoleDescription {
    try await call {
      let output = try await client.userRolesCreateRole(.init(body: .json(request)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Updates a custom role.
  public func updateRole(id: String, request: RoleUpdateRequest) async throws(KTalkError)
    -> RoleDescription
  {
    try await call {
      let output = try await client.userRolesUpdateRole(
        .init(path: .init(roleId: id), body: .json(request)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "role", identifier: id)
      }
    }
  }

  /// Deletes a custom role.
  public func deleteRole(id: String) async throws(KTalkError) {
    try await call {
      let output = try await client.userRolesDeleteRole(.init(path: .init(roleId: id)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "role", identifier: id)
      }
    }
  }

  /// Lists the permissions available for each product.
  public func permissions() async throws(KTalkError) -> [ProductPermissions] {
    try await call {
      let output = try await client.userRolesGetAllPermissions(.init())
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Lists the default roles in the space.
  public func defaultRoles() async throws(KTalkError) -> [RoleDescription] {
    try await call {
      let output = try await client.userRolesGetDefaultRoles(.init())
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }
}
