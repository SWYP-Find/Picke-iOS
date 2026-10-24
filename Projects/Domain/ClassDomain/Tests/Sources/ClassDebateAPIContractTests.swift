@testable import ClassDomain
import ClassDomainInterface
import Foundation
import PickeNetwork
import Testing

struct ClassDebateAPIContractTests {
  @Test
  func 토론_경로와_반박_본문이_명세와_일치한다() throws {
    let key = try #require(UUID(uuidString: "4F0B5C3E-6A8D-4F6B-9A51-2F3D1C7E9B10"))
    let fetch = ClassDebateService.fetch(5)
    let start = ClassDebateService.start(5)
    let reply = ClassDebateService.submitReply(
      classID: 5,
      round: 2,
      content: "반박 내용",
      requestKey: key
    )
    let retry = ClassDebateService.retry(5)

    #expect(try fetch.url().path == "/api/v1/classes/5/battle/debate")
    #expect(fetch.method == .get)
    #expect(try start.url().path == "/api/v1/classes/5/battle/debate")
    #expect(start.method == .post)
    #expect(try reply.url().path == "/api/v1/classes/5/battle/debate/replies")
    #expect(reply.method == .post)
    #expect(try retry.url().path == "/api/v1/classes/5/battle/debate/retry")
    #expect(retry.method == .post)

    let parameters = try #require(reply.parameters)
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(parameters)) as? [String: Any]
    #expect(json?["roundIndex"] as? Int == 2)
    #expect(json?["content"] as? String == "반박 내용")
    #expect(json?["requestKey"] as? String == key.uuidString)
  }

  @Test
  func 토론_응답은_서버_라운드와_입장을_그대로_사용한다() throws {
    let json = """
    {
      "sessionId": 7, "status": "WAITING_USER", "round": 2,
      "canReply": true, "canRetry": false,
      "philosopher": { "code": "KANT", "name": "칸트" },
      "participantOption": { "optionId": 31, "title": "창작이다" },
      "opponentOption": { "optionId": 32, "title": "창작이 아니다" },
      "messages": [
        { "messageId": 101, "round": 1, "speaker": "AI", "content": "첫 주장" },
        { "messageId": 102, "round": 1, "speaker": "USER", "content": "첫 반박" }
      ],
      "aiNotice": "AI의 주장이에요", "replyMinLength": 50, "replyMaxLength": 1000
    }
    """

    let debate = try JSONDecoder().decode(ClassDebateDTO.self, from: Data(json.utf8)).toDomain()
    #expect(debate.round == 2)
    #expect(debate.canReply)
    #expect(debate.participantOptionTitle == "창작이다")
    #expect(debate.opponentOptionTitle == "창작이 아니다")
    #expect(debate.messages.map(\.speaker) == [.ai, .user])
    #expect(debate.replyMinLength == 50)
    #expect(debate.replyMaxLength == 1000)
  }
}
