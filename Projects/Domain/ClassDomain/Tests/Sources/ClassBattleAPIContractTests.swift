@testable import ClassDomain
import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork
import Testing

struct ClassBattleAPIContractTests {
  @Test
  func 클래스_배틀_경로와_투표_의견_요청_본문이_명세와_일치한다() throws {
    let detail = ClassBattleService.detail(classID: 5)
    let preVote = ClassBattleService.preVote(classID: 5, optionID: 31)
    let postVote = ClassBattleService.postVote(classID: 5, optionID: 32)
    let publish = ClassBattleService.publishPerspective(classID: 5, content: "의견")
    let perspectives = ClassBattleService.perspectives(
      classID: 5,
      cursor: "next",
      size: 10,
      optionID: 31,
      sort: "popular"
    )

    #expect(try detail.url().path == "/api/v1/classes/5/battle")
    #expect(detail.method == .get)
    #expect(try preVote.url().path == "/api/v1/classes/5/battle/votes/pre")
    #expect(preVote.method == .post)
    #expect(try postVote.url().path == "/api/v1/classes/5/battle/votes/post")
    #expect(postVote.method == .post)
    #expect(try ClassBattleService.ttsComplete(classID: 5).url().path == "/api/v1/classes/5/battle/votes/tts-complete")
    #expect(try ClassBattleService.myVotes(classID: 5).url().path == "/api/v1/classes/5/battle/votes/me")
    #expect(try ClassBattleService.voteStats(classID: 5).url().path == "/api/v1/classes/5/battle/vote-stats")
    #expect(try publish.url().path == "/api/v1/classes/5/battle/perspectives")
    #expect(publish.method == .post)
    #expect(try perspectives.url().path == "/api/v1/classes/5/battle/perspectives")
    #expect(try ClassBattleService.myPerspectives(classID: 5).url().path == "/api/v1/classes/5/battle/perspectives/me")

    guard let preVoteParameters = preVote.parameters,
          let postVoteParameters = postVote.parameters,
          let publishParameters = publish.parameters,
          let perspectiveParameters = perspectives.parameters
    else {
      Issue.record("배틀 요청 파라미터가 없습니다.")
      return
    }
    let encoder = JSONEncoder()
    let preVoteJSON = try JSONSerialization.jsonObject(with: encoder.encode(preVoteParameters)) as? [String: Int]
    let postVoteJSON = try JSONSerialization.jsonObject(with: encoder.encode(postVoteParameters)) as? [String: Int]
    let publishJSON = try JSONSerialization.jsonObject(with: encoder.encode(publishParameters)) as? [String: String]
    let perspectiveJSON = try JSONSerialization.jsonObject(with: encoder.encode(perspectiveParameters)) as? [String: Any]
    #expect(preVoteJSON == ["optionId": 31])
    #expect(postVoteJSON == ["optionId": 32])
    #expect(publishJSON == ["content": "의견"])
    #expect(perspectiveJSON?["cursor"] as? String == "next")
    #expect(perspectiveJSON?["size"] as? Int == 10)
    #expect(perspectiveJSON?["optionId"] as? Int == 31)
    #expect(perspectiveJSON?["sort"] as? String == "popular")
  }

  @Test
  func 투표_의견_영수증과_통계가_서버_값을_복원한다() throws {
    let receiptJSON = """
    {"voteId":100,"status":"PRE_VOTE"}
    """
    let perspectiveJSON = """
    {"perspectiveId":50,"status":"PUBLISHED","createdAt":"2026-10-21T12:00:00"}
    """
    let statsJSON = """
    {"options":[{"optionId":31,"title":"창작이다","voteCount":7,"ratio":58.3}],
    "totalCount":12,"updatedAt":"2026-10-21T12:00:00"}
    """

    let vote = try JSONDecoder().decode(ClassVoteReceiptDTO.self, from: Data(receiptJSON.utf8)).toDomain()
    let perspective = try JSONDecoder().decode(ClassPerspectiveReceiptDTO.self, from: Data(perspectiveJSON.utf8)).toDomain()
    let stats = try JSONDecoder().decode(ClassVoteStatsDTO.self, from: Data(statsJSON.utf8)).toDomain()

    #expect(vote.voteID == 100)
    #expect(vote.status == .preVote)
    #expect(perspective.id == 50)
    #expect(perspective.status == "PUBLISHED")
    #expect(stats.totalCount == 12)
    #expect(stats.options.first?.voteCount == 7)
    #expect(stats.options.first?.ratio == 58.3)
  }

  @Test
  func 클래스_배틀_응답은_클래스_권한과_배틀_진행을_함께_복원한다() throws {
    let json = """
    {"classId":5,"myRole":"MEMBER","closeAt":"2026-12-31T23:59:59","closed":false,
    "commentRequired":true,"canParticipate":true,"participationCompleted":false,
    "battle":{"battleInfo":{"battleId":9,"title":"AI가 쓴 글도 창작일까?",
    "options":[{"optionId":31,"label":"A","title":"창작이다"}]},
    "userVoteStatus":"PRE_VOTE","currentStep":"PRE_VOTE"}}
    """
    let session = try JSONDecoder().decode(ClassBattleSessionDTO.self, from: Data(json.utf8)).toDomain()

    #expect(session.classID == 5)
    #expect(session.myRole == .member)
    #expect(session.canParticipate)
    #expect(session.battle.currentStep == .preVote)
    #expect(session.battle.options.first?.id == 31)
  }

  @Test
  func 의견_페이지와_투표_이력은_서버_응답을_그대로_복원한다() throws {
    let voteJSON = """
    {"battleTitle":"AI가 쓴 글도 창작일까?","preVote":{"optionId":31,"label":"A","title":"창작이다"},
    "postVote":{"optionId":32,"label":"B","title":"창작이 아니다"},"status":"COMPLETED","opinionChanged":true}
    """
    let pageJSON = """
    {"items":[{"perspectiveId":50,"user":{"userTag":"u1","nickname":"피케"},
    "option":{"optionId":31,"label":"A","title":"창작이다"},"content":"의견",
    "likeCount":3,"commentCount":1,"isLiked":false,"isMyPerspective":true,
    "createdAt":"2026-10-21T12:00:00"}],"nextCursor":"next","hasNext":true}
    """
    let history = try JSONDecoder().decode(ClassVoteHistoryDTO.self, from: Data(voteJSON.utf8)).toDomain()
    let page = try JSONDecoder().decode(ClassPerspectivePageDTO.self, from: Data(pageJSON.utf8)).toDomain()

    #expect(history.status == .completed)
    #expect(history.opinionChanged == true)
    #expect(page.items.first?.id == 50)
    #expect(page.items.first?.isMyPerspective == true)
    #expect(page.nextCursor == "next")
    #expect(page.hasNext)
  }
}
