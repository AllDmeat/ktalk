import Foundation

extension KTalkClient {
  /// A webhook subscription.
  public typealias Webhook = Components.Schemas.SkbKontur_Talk_Web_Entities_Webhooks_TalkWebhook
  /// A request to create a webhook.
  public typealias CreateWebhookRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Webhooks_TalkCreateWebhookRequest
  /// A request to activate a webhook.
  public typealias ActivateWebhookRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Webhooks_TalkActivateWebhookRequest

  /// Lists the active webhooks in the space.
  public func listWebhooks() async throws(KTalkError) -> [Webhook] {
    try await call {
      let output = try await client.webhooksGetWebhooks(.init())
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Creates a webhook. The server posts an activation key to the webhook URL.
  public func createWebhook(_ request: CreateWebhookRequest) async throws(KTalkError) -> Webhook {
    try await call {
      let output = try await client.webhooksCreateWebhook(.init(body: .json(request)))
      switch output {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let statusCode, _):
        throw statusError(statusCode: statusCode, body: nil)
      }
    }
  }

  /// Activates a webhook with the activation key delivered to its URL.
  public func activateWebhook(webhookKey: String, request: ActivateWebhookRequest)
    async throws(KTalkError)
  {
    try await call {
      let output = try await client.webhooksActivateWebhook(
        .init(path: .init(webhookKey: webhookKey), body: .json(request)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "webhook", identifier: webhookKey)
      }
    }
  }

  /// Deletes a webhook.
  public func deleteWebhook(webhookKey: String) async throws(KTalkError) {
    try await call {
      let output = try await client.webhooksDeleteWebhook(
        .init(path: .init(webhookKey: webhookKey)))
      switch output {
      case .ok: return
      case .undocumented(let statusCode, _):
        throw notFoundOrStatus(statusCode, resource: "webhook", identifier: webhookKey)
      }
    }
  }
}
