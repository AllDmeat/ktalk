import Foundation

extension KTalkClient {
  /// A survey.
  public typealias Survey = Components.Schemas.SkbKontur_Talk_Web_Entities_Surveys_TalkSurvey
  /// A list of surveys.
  public typealias SurveyList = Components.Schemas
    .SkbKontur_Talk_Web_Entities_Surveys_TalkSurveyList
  /// A request to create or update a survey.
  public typealias SurveyRequest =
    Components.Schemas.SkbKontur_Talk_Web_Entities_Surveys_TalkCreateOrUpdateSurveyRequest

  /// Lists the surveys in the space.
  public func listSurveys() async throws(KTalkError) -> SurveyList {
    try await call {
      switch try await client.domainSurveysGet(.init()) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Fetches a survey by id.
  public func survey(id: String) async throws(KTalkError) -> Survey {
    try await call {
      switch try await client.domainSurveysGet2(.init(path: .init(surveyId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "survey", identifier: id)
      }
    }
  }

  /// Creates a survey.
  public func createSurvey(_ request: SurveyRequest) async throws(KTalkError) -> Survey {
    try await call {
      switch try await client.domainSurveysCreate(.init(body: .json(request))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _): throw statusError(statusCode: s, body: nil)
      }
    }
  }

  /// Updates a survey.
  public func updateSurvey(id: String, request: SurveyRequest) async throws(KTalkError) -> Survey {
    try await call {
      switch try await client.domainSurveysUpdate(
        .init(path: .init(surveyId: id), body: .json(request)))
      {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "survey", identifier: id)
      }
    }
  }

  /// Publishes a survey.
  public func publishSurvey(id: String) async throws(KTalkError) -> Survey {
    try await call {
      switch try await client.domainSurveysPublish(.init(path: .init(surveyId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "survey", identifier: id)
      }
    }
  }

  /// Unpublishes a survey.
  public func unpublishSurvey(id: String) async throws(KTalkError) -> Survey {
    try await call {
      switch try await client.domainSurveysUnpublish(.init(path: .init(surveyId: id))) {
      case .ok(let ok): return try ok.body.json
      case .undocumented(let s, _):
        throw notFoundOrStatus(s, resource: "survey", identifier: id)
      }
    }
  }
}
