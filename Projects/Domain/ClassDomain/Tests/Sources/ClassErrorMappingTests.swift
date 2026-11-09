@testable import ClassDomain
import ClassDomainInterface
import Foundation
import Testing

struct ClassErrorMappingTests {
  @Test(arguments: [
    ("CLASS_404_CODE", ClassError.invalidCode),
    ("CLASS_409_CLOSED", .closed),
    ("CLASS_409_TICKET_ENDED", .closed),
    ("CLASS_409_JOINED", .alreadyJoined),
    ("CLASS_409_NAME", .duplicateName),
    ("CLASS_404", .notFound),
    ("CLASS_409_FULL", .full),
    ("CLASS_409_DELETED", .deleted),
    ("CLASS_409_REQUEST_KEY", .requestKeyConflict),
    ("CLASS_409_OWNER", .ownClass),
    ("CLASS_403_REMOVED", .removed),
    ("CLASS_403_TICKET", .ticketRequired),
    ("CLASS_403_OWNER", .ownerOnly),
    ("CLASS_403_MEMBER", .memberOnly),
    ("CLASS_403_OWNER_LEAVE", .ownerCannotLeave),
    ("CLASS_404_MEMBER", .memberNotFound),
    ("CLASS_400_DEADLINE", .invalidDeadline),
    ("CLASS_400_DEADLINE_EXT", .deadlineExtensionOnly),
    ("CLASS_400_BATTLE", .invalidBattle),
    ("CLASS_404_TOPIC_VERSION", .topicVersionNotFound),
    ("CLASS_409_TOPIC_DRAFT_USED", .topicDraftUsed),
    ("CLASS_500_CODE", .inviteCodeFailed),
  ])
  func 명세_에러_코드는_클래스_에러로_바뀐다(
    code: String,
    expected: ClassError
  ) {
    #expect(ClassErrorMapper.map(code: code, message: "서버 문구", fallback: "기본 문구") == expected)
  }

  @Test
  func 모르는_코드는_서버_메시지를_보여준다() {
    #expect(ClassErrorMapper.map(code: "COMMON_400", message: "형식을 확인해 주세요.", fallback: "기본 문구") == .network("형식을 확인해 주세요."))
  }

  @Test
  func 메시지가_없으면_기본_문구를_보여준다() {
    #expect(ClassErrorMapper.map(code: nil, message: nil, fallback: "기본 문구") == .network("기본 문구"))
  }

  @Test
  func 알수없는_내부_오류는_구현_상세를_화면에_표시하지_않는다() {
    let error = ClassError.unknown("AuthenticationError.excessiveRefresh")
    #expect(error.message == "클래스 요청을 처리하지 못했습니다. 다시 시도해 주세요.")
  }

  @Test
  func 알수없는_오류여도_명시적인_사용자_안내는_유지한다() {
    let message = "AI 주제 생성 시간이 초과됐어요. 다시 확인해 주세요."
    #expect(ClassError.userMessage(message).message == message)
    #expect(ClassError.unknown("AuthenticationError.excessiveRefresh: 인증 토큰 갱신 실패").message !=
      "AuthenticationError.excessiveRefresh: 인증 토큰 갱신 실패")
  }
}
