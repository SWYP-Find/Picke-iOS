@testable import ClassDomain
import APIEndpoint
import ClassDomainInterface
import Foundation
import PickeNetwork
import Testing

struct ClassMemberAPITests {
  @Test
  func 멤버_요청은_명세의_경로와_메서드를_사용한다() throws {
    let list = ClassMemberService.members(classID: 42)
    let rename = ClassMemberService.updateMyName(classID: 42, name: "새 이름")
    let remove = ClassMemberService.remove(classID: 42, memberID: 12)

    #expect(try list.url().path == "/api/v1/classes/42/members")
    #expect(list.method == .get)
    #expect(list.parameters == nil)
    #expect(try rename.url().path == "/api/v1/classes/42/members/me")
    #expect(rename.method == .patch)
    let body = try #require(rename.parameters)
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(body)) as? [String: String]
    #expect(json == ["displayName": "새 이름"])
    #expect(try remove.url().path == "/api/v1/classes/42/members/12")
    #expect(remove.method == .delete)
    #expect(remove.parameters == nil)
  }

  @Test
  func 멤버_응답의_me와_원격_아바타를_도메인에_반영한다() throws {
    let json = """
    [
      {"memberId":10,"displayName":"운영자","role":"OWNER","characterUrl":null,"me":false},
      {"memberId":11,"displayName":"참여자","role":"MEMBER",\
      "characterUrl":"https://example.com/avatar.png","me":true}
    ]
    """
    let payload = try JSONDecoder().decode([ClassMemberDTO].self, from: Data(json.utf8))
    let members = ClassMemberDTO.toMemberList(payload)

    #expect(members.currentMemberID == 11)
    #expect(members.members.map(\.id) == [10, 11])
    #expect(members.members[0].isOwner)
    #expect(members.members[1].characterURL?.absoluteString == "https://example.com/avatar.png")
  }

  @Test
  func 본인_행이_없으면_임의의_멤버를_본인으로_취급하지_않는다() throws {
    let json = """
    [{"memberId":10,"displayName":"운영자","role":"OWNER","characterUrl":null,"me":false}]
    """
    let payload = try JSONDecoder().decode([ClassMemberDTO].self, from: Data(json.utf8))
    // 참여하지 않은 운영자가 보는 명단처럼 내 행이 없어도 실패하지 않고, 아무도 본인으로 잡지 않는다.
    let members = ClassMemberDTO.toMemberList(payload)
    #expect(members.currentMemberID == nil)
    #expect(members.members.map(\.id) == [10])
  }
}
