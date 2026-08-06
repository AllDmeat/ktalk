import Synchronization
import Testing

@testable import KTalkSDK

@Suite("Pagination")
struct PaginationTests {
  private func makeClient() throws -> KTalkClient {
    try KTalkClient(baseURL: "https://example.ktalk.ru", token: "test-token")
  }

  @Test("collectAll follows nextPageToken across pages")
  func collectsAllPages() async throws {
    let client = try makeClient()
    let pages: [String?: Page<Int>] = [
      nil: Page(items: [1, 2], nextPageToken: "p2"),
      "p2": Page(items: [3, 4], nextPageToken: "p3"),
      "p3": Page(items: [5], nextPageToken: nil),
    ]

    let all = try await client.collectAll { (token) throws(KTalkError) -> Page<Int> in
      pages[token] ?? Page(items: [])
    }

    #expect(all == [1, 2, 3, 4, 5])
  }

  @Test("collectAll returns a single page when there is no next cursor")
  func collectsSinglePage() async throws {
    let client = try makeClient()
    let all = try await client.collectAll { (_) throws(KTalkError) -> Page<Int> in
      Page(items: [7, 8, 9], nextPageToken: nil)
    }
    #expect(all == [7, 8, 9])
  }

  @Test("collectAll stops if the cursor does not advance")
  func stopsOnNonAdvancingCursor() async throws {
    let client = try makeClient()
    let calls = Mutex(0)

    let all = try await client.collectAll { (_) throws(KTalkError) -> Page<Int> in
      calls.withLock { $0 += 1 }
      // Always advertises the same non-nil cursor — must not loop forever.
      return Page(items: [1], nextPageToken: "same")
    }

    #expect(all == [1, 1])
    #expect(calls.withLock { $0 } == 2)
  }

  @Test("Page.map preserves cursors")
  func mapPreservesCursors() {
    let page = Page(items: [1, 2], nextPageToken: "n", prevPageToken: "p")
    let mapped = page.map { $0 * 10 }
    #expect(mapped.items == [10, 20])
    #expect(mapped.nextPageToken == "n")
    #expect(mapped.prevPageToken == "p")
    #expect(page.hasNextPage)
  }
}
