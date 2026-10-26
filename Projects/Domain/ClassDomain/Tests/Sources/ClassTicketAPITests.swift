@testable import ClassDomain
import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeCoreUtility
import PickeNetwork
import Testing

struct ClassTicketAPITests {
  @Test
  func 서버_이용권_에러_코드를_화면_오류로_매핑한다() {
    let cases: [(Int, String, ClassTicketError)] = [
      (400, "COMMON_400", .invalidCode),
      (404, "TICKET_404_CODE", .invalidCode),
      (409, "TICKET_409_REVOKED", .revoked),
      (409, "TICKET_409_REG_EXP", .registrationExpired),
      (409, "TICKET_409_CLAIMED", .claimed),
      (409, "TICKET_409_ACTIVE", .activeTicket),
      (404, "TICKET_404", .notFound)
    ]

    for (status, code, expected) in cases {
      let error = PickeNetworkError.response(
        ResponseError(httpStatus: status, code: code)
      )
      #expect(ClassRepositoryImpl.ticketError(error) == expected)
    }
  }

  @Test
  func 코드_미리보기와_등록_요청은_같은_코드를_각각_쿼리와_JSON으로_전달한다() throws {
    let preview = ClassTicketService.preview(code: "PICKE-AB12-CD34")
    let register = ClassTicketService.register(code: "PICKE-AB12-CD34")
    let me = ClassTicketService.me

    #expect(try preview.url().path == "/api/v1/class-tickets/preview")
    #expect(preview.method == .get)
    #expect(try register.url().path == "/api/v1/class-tickets/register")
    #expect(register.method == .post)
    #expect(try me.url().path == "/api/v1/class-tickets/me")
    #expect(me.method == .get)
    #expect(me.parameters == nil)

    let previewBody = try #require(preview.parameters)
    let registerBody = try #require(register.parameters)
    let previewJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(previewBody)) as? [String: String]
    let registerJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(registerBody)) as? [String: String]
    #expect(previewJSON == ["code": "PICKE-AB12-CD34"])
    #expect(registerJSON == ["code": "PICKE-AB12-CD34"])
  }

  @Test
  func 서버_로컬_시각은_한국_시간으로_읽고_만료일을_재계산하지_않는다() throws {
    let previewJSON = """
    {"capacity":15,"registerBy":"2027-09-01T00:00:00","usageMonths":6,"registeredByMe":false}
    """
    let ticketJSON = """
    {"ticketId":3,"capacity":15,"status":"ACTIVE","activatedAt":"2026-10-01T10:00:00",\
    "expiresAt":"2027-04-01T10:00:00","remainingDays":162,"readGraceEndsAt":"2027-05-01T10:00:00"}
    """
    let preview = try JSONDecoder().decode(ClassTicketPreviewDTO.self, from: Data(previewJSON.utf8)).toDomain()
    let ticket = try JSONDecoder().decode(ClassTicketDTO.self, from: Data(ticketJSON.utf8)).toDomain()

    #expect(preview.capacity == 15)
    #expect(preview.usageMonths == 6)
    #expect(ticket.id == 3)
    #expect(ticket.remainingDays == 162)
    #expect(ticket.status == .active)
    #expect(ticket.activatedAt == ServerDateParser.parse("2026-10-01T10:00:00"))
    #expect(ticket.expiresAt == ServerDateParser.parse("2027-04-01T10:00:00"))
    #expect(ticket.readGraceEndsAt == ServerDateParser.parse("2027-05-01T10:00:00"))
  }

  @Test
  func 알_수_없는_이용권_상태는_잘못된_응답으로_처리한다() throws {
    let json = """
    {"ticketId":3,"capacity":15,"status":"REVOKED","activatedAt":"2026-10-01T10:00:00",\
    "expiresAt":"2027-04-01T10:00:00","remainingDays":0,"readGraceEndsAt":"2027-05-01T10:00:00"}
    """
    let payload = try JSONDecoder().decode(ClassTicketDTO.self, from: Data(json.utf8))
    #expect(throws: ClassTicketError.invalidResponse) { try payload.toDomain() }
  }
}
