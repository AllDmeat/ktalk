/// KTalkSDK — a Swift client for the Kontur.Talk integrator HTTP API.
///
/// The SDK is layered:
/// - **Generated layer** (added in a later change): `types` + `client` produced by
///   `swift-openapi-generator` from the vendored OpenAPI document.
/// - **Facade layer**: ``KTalkClient`` and its per-tag extensions, wrapping the generated
///   client with typed errors, authentication, retries, and pagination.
///
/// The companion `ktalk` executable is a thin command-line wrapper over this SDK.
public enum KTalkSDK {
  /// The SDK's semantic version, kept in sync with the latest release tag.
  public static let version = "0.0.0"
}
