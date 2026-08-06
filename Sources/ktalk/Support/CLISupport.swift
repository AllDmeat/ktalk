import ArgumentParser
import Foundation
import KTalkSDK

/// Options shared by every command: how to reach the space and authenticate.
struct GlobalOptions: ParsableArguments {
  @Option(
    name: .long,
    help: "Space base URL, e.g. https://example.ktalk.ru (default: $KTALK_BASE_URL).")
  var baseURL: String?

  @Option(name: .long, help: "X-Auth-Token API key (default: $KTALK_TOKEN).")
  var token: String?

  /// Builds a ``KTalkClient`` from the flags, falling back to the environment.
  func makeClient() throws -> KTalkClient {
    let environment = ProcessInfo.processInfo.environment
    guard let base = baseURL ?? environment["KTALK_BASE_URL"], !base.isEmpty else {
      throw ValidationError("Missing base URL. Pass --base-url or set KTALK_BASE_URL.")
    }
    guard let key = token ?? environment["KTALK_TOKEN"], !key.isEmpty else {
      throw ValidationError("Missing token. Pass --token or set KTALK_TOKEN.")
    }
    do {
      return try KTalkClient(baseURL: base, token: key)
    } catch {
      throw ValidationError(error.localizedDescription)
    }
  }
}

/// Decodes a `Decodable` value from a JSON file, for commands that take a request body.
func decodeJSON<T: Decodable>(_ type: T.Type, fromFile path: String) throws -> T {
  let data = try Data(contentsOf: URL(fileURLWithPath: path))
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601
  return try decoder.decode(T.self, from: data)
}

/// Prints an `Encodable` value as pretty-printed JSON to standard output.
func printJSON(_ value: some Encodable) throws {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
  encoder.dateEncodingStrategy = .iso8601
  let data = try encoder.encode(value)
  print(String(decoding: data, as: UTF8.self))
}
