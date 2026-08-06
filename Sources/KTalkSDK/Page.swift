/// A single page of results from a cursor-paginated Kontur.Talk endpoint.
///
/// Kontur.Talk list endpoints return an `entities` array plus opaque `nextPageToken` /
/// `prevPageToken` cursors. Pass `nextPageToken` back to the same endpoint to fetch the
/// following page; a `nil` `nextPageToken` marks the last page.
public struct Page<Element: Sendable>: Sendable {
  /// The items on this page.
  public let items: [Element]
  /// The cursor for the next page, or `nil` if this is the last page.
  public let nextPageToken: String?
  /// The cursor for the previous page, or `nil` if this is the first page.
  public let prevPageToken: String?

  public init(items: [Element], nextPageToken: String? = nil, prevPageToken: String? = nil) {
    self.items = items
    self.nextPageToken = nextPageToken
    self.prevPageToken = prevPageToken
  }

  /// Whether another page is available.
  public var hasNextPage: Bool { nextPageToken != nil }

  /// Returns a new page with `items` transformed by `transform`, preserving the cursors.
  public func map<T: Sendable>(_ transform: (Element) throws -> T) rethrows -> Page<T> {
    Page<T>(
      items: try items.map(transform),
      nextPageToken: nextPageToken,
      prevPageToken: prevPageToken
    )
  }
}

extension Page: Encodable where Element: Encodable {}
extension Page: Decodable where Element: Decodable {}
extension Page: Equatable where Element: Equatable {}

extension KTalkClient {
  /// Follows `nextPageToken` from the first page onward and returns every item.
  ///
  /// - Parameter fetch: Fetches one page given a page token (`nil` for the first page).
  /// - Returns: All items across every page, in order.
  ///
  /// Pagination stops when a page reports no `nextPageToken`. As a safety net against a
  /// server that keeps returning the same cursor, it also stops if the cursor does not
  /// advance.
  public func collectAll<Element>(
    _ fetch: (_ pageToken: String?) async throws(KTalkError) -> Page<Element>
  ) async throws(KTalkError) -> [Element] {
    var all: [Element] = []
    var token: String?
    while true {
      let page = try await fetch(token)
      all.append(contentsOf: page.items)
      guard let next = page.nextPageToken, next != token else { break }
      token = next
    }
    return all
  }
}
