@testable import ClassDomain
import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeCoreUtility
import PickeNetwork
import Testing

struct ClassResultAPIContractTests {
  @Test
  func 결과_열람_만료와_권한_오류를_구분한다() {
    #expect(ClassRepositoryImpl.resultError(code: "CLASS_409_RESULT_EXPIRED", message: nil) == .resultExpired)
    #expect(ClassRepositoryImpl.resultError(code: "CLASS_403_MEMBER", message: nil) == .accessDenied)
    #expect(ClassRepositoryImpl.feedbackError(code: "CLASS_409_RESULT_EXPIRED") == .resultExpired)
    #expect(ClassRepositoryImpl.feedbackError(code: "CLASS_403_OWNER") == .accessDenied)
    #expect(ClassRepositoryImpl.feedbackError(code: "CLASS_409_REPORT_RETRY") == .generationFailed)
  }

  @Test
  func 감싼_네트워크_디코딩_오류는_재시도_대상에서_제외한다() {
    let error = ClassRepositoryImpl.feedbackError(PickeNetworkError.decoding(.dataMissing))
    #expect(error == .invalidResponse)
    #expect(!error.isRetryable)
  }

  @Test
  func 결과_리포트_인사이트_경로를_분리한다() throws {
    #expect(ClassResultService.result(5).path == "classes/5/result")
    #expect(ClassResultService.myReport(5).path == "classes/5/result/my-report")
    #expect(ClassResultService.insight(5).path == "classes/5/result/insight")
    #expect(ClassResultService.retryInsight(5).path == "classes/5/result/insight/retry")
    #expect(try ClassResultService.result(5).url().path == "/api/v1/classes/5/result")
    #expect(try ClassResultService.myReport(5).url().path == "/api/v1/classes/5/result/my-report")
    #expect(try ClassResultService.insight(5).url().path == "/api/v1/classes/5/result/insight")
    #expect(try ClassResultService.retryInsight(5).url().path == "/api/v1/classes/5/result/insight/retry")
  }


  @Test
  func 결과_통계는_멤버별_추정값_없이_서버_집계만_보존한다() throws {
    let json = """
    {
      "classId": 5, "closeAt": "2026-12-31T23:59:59.123Z", "closed": true,
      "stats": {
        "activeMemberCount": 12, "completedCount": 10, "participationRate": 83.3,
        "commentWriterCount": 9, "commentRate": 75.0, "postVoteCount": 11,
        "midVoteEnabled": true, "midVoteCount": 10,
        "midVoteCheckpoints": [{
          "checkpointId": 801, "voteCount": 10,
          "options": [{"optionId": 9002, "label": "무죄", "voteCount": 6, "ratio": 60.0}]
        }],
        "options": [
          { "optionId": 31, "title": "창작이다", "preVoteCount": 8,
            "postVoteCount": 6, "postVoteRatio": 54.5 }
        ]
      },
      "myReportState": null, "insightState": "SUCCEEDED"
    }
    """

    let result = try JSONDecoder().decode(ClassResultDTO.self, from: Data(json.utf8)).toDomain()
    #expect(result.stats.activeMemberCount == 12)
    #expect(result.closeAt == ServerDateParser.parse("2026-12-31T23:59:59.123Z"))
    #expect(result.stats.completedCount == 10)
    #expect(result.stats.participationRate == 83.3)
    #expect(result.stats.options.first?.id == 31)
    #expect(result.stats.midVoteEnabled)
    #expect(result.stats.midVoteCount == 10)
    #expect(result.stats.midVoteCheckpoints.first?.id == 801)
    #expect(result.stats.midVoteCheckpoints.first?.options.first?.id == 9002)
    #expect(result.stats.midVoteCheckpoints.first?.options.first?.ratio == 60.0)
    #expect(result.myReportState == nil)
    #expect(result.insightState == "SUCCEEDED")
  }

  @Test
  func 생성_대기_리포트를_완료로_표시하지_않는다() throws {
    let personal = try JSONDecoder().decode(
      ClassPersonalReportDTO.self,
      from: Data(#"{"state":"PENDING","feedback":null}"#.utf8)
    )
    #expect(throws: ClassAIFeedbackError.modelNotReady) { try personal.toDomain() }

    let insight = try JSONDecoder().decode(
      ClassInsightDTO.self,
      from: Data(#"{"state":"FAILED","retryable":true,"insightText":null}"#.utf8)
    )
    #expect(throws: ClassAIFeedbackError.serverRetryAvailable) { try insight.toDomain() }
  }

  @Test
  func 개인_피드백의_근거와_분석_범위를_보존한다() throws {
    let json = """
    {
      "state": "SUCCEEDED",
      "preOption": { "optionId": 31, "title": "창작이다", "stance": "처음 의견" },
      "midVotes": [{"checkpointId":801,"optionId":9002,"label":"무죄"}],
      "postOption": { "optionId": 32, "title": "창작이 아니다", "stance": "바뀐 의견" },
      "perspectiveCount": 1,
      "commentCount": 2,
      "feedback": {
        "headline": "판단을 바꾼 이유", "judgmentBasis": "근거를 비교했어요",
        "strength": null, "nextFocus": null, "nextQuestion": "왜 그럴까요?",
        "coverage": "partial", "excludedCount": 2,
        "evidence": [{
          "field": "judgment_basis", "sourceType": "PERSPECTIVE", "sourceId": 50,
          "quote": "짧은 인용", "content": "삭제되지 않은 원문"
        }]
      }
    }
    """

    let feedback = try JSONDecoder().decode(ClassPersonalReportDTO.self, from: Data(json.utf8)).toDomain()
    #expect(feedback.coverage == "partial")
    #expect(feedback.excludedCount == 2)
    #expect(feedback.evidence.first?.sourceID == 50)
    #expect(feedback.evidence.first?.content == "삭제되지 않은 원문")
    #expect(feedback.evidence.first?.quote == "짧은 인용")
    #expect(feedback.preOption?.id == 31)
    #expect(feedback.midVotes == [ClassMidVoteChoice(checkpointID: 801, optionID: 9002, label: "무죄")])
    #expect(feedback.postOption?.title == "창작이 아니다")
    #expect(feedback.perspectiveCount == 1)
    #expect(feedback.commentCount == 2)
  }

  @Test
  func 투표_이력의_중간_선택을_보존한다() throws {
    let json = """
    {"battleTitle":"Picke(TTS) 배틀","preVote":{"optionId":31,"label":"A","title":"창작이다"},
    "midVotes":[{"checkpointId":801,"optionId":9002,"label":"무죄"}],
    "postVote":null,"status":"PRE_VOTE","opinionChanged":null}
    """

    let history = try JSONDecoder().decode(ClassVoteHistoryDTO.self, from: Data(json.utf8)).toDomain()
    #expect(history.midVotes == [ClassMidVoteChoice(checkpointID: 801, optionID: 9002, label: "무죄")])
  }

  @Test
  func 중간_투표가_없는_이전_응답도_빈_선택으로_읽는다() throws {
    let json = """
    {"battleTitle":"일반 배틀","preVote":{"optionId":31,"label":"A","title":"창작이다"},
    "postVote":null,"status":"PRE_VOTE","opinionChanged":null}
    """

    let history = try JSONDecoder().decode(ClassVoteHistoryDTO.self, from: Data(json.utf8)).toDomain()
    #expect(history.midVotes.isEmpty)
  }

  @Test
  func 운영자_인사이트의_근거와_대표_의견을_보존한다() throws {
    let json = """
    {
      "state": "SUCCEEDED", "retryable": false,
      "insightText": "의견을 비교했어요", "coverage": "full", "excludedCount": 0,
      "evidence": [{"sourceType": "PERSPECTIVE", "id": 50, "content": "근거 의견"}],
      "highlights": [{"sourceType": "PERSPECTIVE", "id": 51, "content": "대표 의견"}]
    }
    """

    let insight = try JSONDecoder().decode(ClassInsightDTO.self, from: Data(json.utf8)).toDomain()
    #expect(insight.text == "의견을 비교했어요")
    #expect(insight.coverage == "full")
    #expect(insight.evidence.first?.sourceID == 50)
    #expect(insight.highlights.first?.content == "대표 의견")
  }
}
