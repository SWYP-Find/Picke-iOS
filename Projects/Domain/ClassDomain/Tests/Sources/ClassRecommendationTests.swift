@testable import ClassDomain
import ClassDomainInterface
import Dependencies
import Foundation
import PickeCoreUtility
import PickeNetwork
import Testing

struct ClassRecommendationTests {
  @Test
  func 추천_요청은_수준과_카테고리와_검색어를_쿼리로_보낸다() throws {
    let request = ClassBattleRecommendationService.recommendations(
      filter: .init(keyword: "인간 자유", level: .high, categories: [.philosophy, .society])
    )
    let url = try request.url()
    guard let parameters = request.parameters else {
      Issue.record("추천 요청 쿼리가 누락됨")
      return
    }
    let json = try JSONEncoder().encode(parameters)
    let query = try #require(JSONSerialization.jsonObject(with: json) as? [String: String])

    #expect(url.path == "/api/v1/class-battle-recommendations")
    #expect(request.method == .get)
    #expect(query == [
      "difficulty": "INTERMEDIATE",
      "categories": "철학,사회",
      "keyword": "인간 자유",
    ])
  }

  @Test
  func 추천_응답은_위치가_뒤바뀐_AB_선택지를_올바르게_매핑한다() async throws {
    let json = """
    {"statusCode":200,"data":{"items":[{
      "battleId":12,"title":"AI가 쓴 글도 창작일까?","summary":"요약",
      "thumbnailUrl":"https://example.com/thumb.png","category":"철학",
      "difficulty":"BEGINNER","audioDuration":180,
      "options":[
        {"optionId":32,"position":"B","title":"창작이 아니다","stance":"반대 근거","representative":"칸트","imageUrl":"https://example.com/b.png"},
        {"optionId":31,"position":"A","title":"창작이다","stance":"찬성 근거","representative":"니체","imageUrl":"https://example.com/a.png"}
      ]
    }]}}
    """
    let repository = withDependencies {
      $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
    } operation: {
      ClassRepositoryImpl()
    }

    let battles = try await repository.fetchRecommendedBattles(filter: .init(category: .philosophy))
    let battle = try #require(battles.first)
    #expect(battles.count == 1)
    #expect(battle.id == 12)
    #expect(battle.thumbnailURL?.absoluteString == "https://example.com/thumb.png")
    #expect(battle.category == .philosophy)
    #expect(battle.level == .middle)
    #expect(battle.audioDuration == 180)
    #expect(battle.optionATitle == "창작이다")
    #expect(battle.optionADescription == "찬성 근거")
    #expect(battle.philosopherA == "니체")
    #expect(battle.philosopherAImageURL?.absoluteString == "https://example.com/a.png")
    #expect(battle.optionBTitle == "창작이 아니다")
    #expect(battle.philosopherB == "칸트")
  }

  @Test
  func 라이브_클래스_목록은_목_저장소가_아닌_서버를_쓴다() async throws {
    let json = #"{"statusCode":200,"data":[]}"#
    let live = ClassLiveRepository(
      mock: MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: []),
      api: withDependencies {
        $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
      } operation: {
        ClassRepositoryImpl()
      }
    )

    #expect(try await live.fetchMyClasses().isEmpty)
  }

  @Test
  func 서버_에러_메시지는_ClassError로_전달된다() async throws {
    let json = #"{"statusCode":400,"error":{"code":"CLASS_400_RECOMMEND_CONDITION","message":"추천 조건 오류"}}"#
    let repository = withDependencies {
      $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
    } operation: {
      ClassRepositoryImpl()
    }
    do {
      _ = try await repository.fetchRecommendedBattles(filter: .init(category: .philosophy))
      Issue.record("서버 오류가 성공으로 처리됨")
    } catch {
      #expect(error as? ClassError == .network("추천 조건 오류"))
    }
  }

  @Test
  func 클래스_생성_요청은_서버_계약의_필드와_KST_시각을_보낸다() throws {
    let deadline = try #require("2026-12-31T23:59:59".date(as: .serverDateTime))
    let creation = ClassCreation(
      name: "철학 토론",
      deadline: deadline,
      battleId: 12,
      allowsAnonymousOpinion: false,
      requiresComment: true,
      ownerParticipates: false
    )
    let request = ClassroomService.create(creation)
    guard let body = request.parameters else {
      Issue.record("클래스 생성 요청 본문이 누락됨")
      return
    }
    let json = try JSONEncoder().encode(body)
    let fields = try #require(JSONSerialization.jsonObject(with: json) as? [String: Any])

    #expect(try request.url().path == "/api/v1/classes")
    #expect(request.method == .post)
    #expect(fields["name"] as? String == "철학 토론")
    #expect(fields["battleId"] as? Int == 12)
    #expect(fields["topicVersionId"] == nil)
    #expect(fields["deadline"] as? String == "2026-12-31T23:59:59")
    #expect((fields["commentRequired"] as? Bool) == true)
    #expect((fields["ownerParticipates"] as? Bool) == false)
    #expect(fields["allowsAnonymousOpinion"] == nil)
  }

  @Test
  func 마감일_미설정_클래스는_서버에_먼_미래_날짜를_보내지_않는다() throws {
    let creation = ClassCreation(
      name: "철학 토론",
      deadline: .distantFuture,
      battleId: 12,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    guard let body = ClassroomService.create(creation).parameters else {
      Issue.record("클래스 생성 요청 본문이 누락됨")
      return
    }
    let json = try JSONEncoder().encode(body)
    let fields = try #require(JSONSerialization.jsonObject(with: json) as? [String: Any])

    #expect(fields["deadline"] == nil)
  }

  @Test
  func 커스텀_클래스는_선택된_서버_주제_버전만_보낸다() throws {
    let creation = ClassCreation(
      name: "AI 토론",
      deadline: .distantFuture,
      topicVersionId: 12,
      allowsAnonymousOpinion: false,
      requiresComment: true
    )
    guard let body = ClassroomService.create(creation).parameters else {
      Issue.record("클래스 생성 요청 본문이 누락됨")
      return
    }
    let json = try JSONEncoder().encode(body)
    let fields = try #require(JSONSerialization.jsonObject(with: json) as? [String: Any])

    #expect(fields["topicVersionId"] as? Int == 12)
    #expect(fields["battleId"] == nil)
    #expect(fields["deadline"] == nil)
  }

  @Test
  func 참여_미리보기는_실제_서버_필드만_해석한다() async throws {
    let json = """
    {"statusCode":200,"data":{
      "inviteCode":"A7K2MP","name":"철학 토론","battleTitle":"AI 창작",
      "battleThumbnailUrl":"https://example.com/a.png","battleType":"TTS",
      "memberCount":12,"capacity":30,"closeAt":"2026-12-31T23:59:59"
    }}
    """
    let repository = withDependencies {
      $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
    } operation: {
      ClassRepositoryImpl()
    }

    let preview = try await repository.fetchClassPreview(joinCode: "A7K2MP")
    #expect(preview.inviteCode == "A7K2MP")
    #expect(preview.battleTitle == "AI 창작")
    #expect(preview.capacity == 30)
    #expect(preview.closeAt.formatted(.serverDateTime) == "2026-12-31T23:59:59")
  }

  @Test
  func 내_클래스_목록은_서버_응답의_역할과_마감_상태를_반영한다() async throws {
    let json = """
    {"statusCode":200,"data":[{
      "classId":5,"name":"철학 토론","myRole":"MEMBER","battleId":12,
      "battleTitle":"AI 창작","battleThumbnailUrl":null,"battleType":"TTS",
      "memberCount":12,"capacity":30,"closeAt":"2026-12-31T23:59:59",
      "closed":true,"createdAt":"2026-10-21T10:00:00"
    }]}
    """
    let repository = withDependencies {
      $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
    } operation: {
      ClassRepositoryImpl()
    }

    let rooms = try await repository.fetchMyClasses()
    let room = try #require(rooms.first)
    #expect(rooms.count == 1)
    #expect(room.id == 5)
    #expect(room.battleType == .tts)
    #expect(room.role == .member)
    #expect(room.status == .closed)
    #expect(room.memberCapacity == 30)
  }

  @Test
  func 상세_응답의_선택적_마감일이_없으면_미설정으로_유지한다() async throws {
    let json = """
    {"statusCode":200,"data":{
      "classId":5,"name":"철학 토론","inviteCode":null,"myRole":"MEMBER",
      "battle":{"battleId":12,"title":"AI 창작","summary":"주제","thumbnailUrl":null},
      "battleType":"CUSTOM",
      "memberCount":12,"capacity":30,"deadline":null,"closeAt":"2026-12-31T23:59:59",
      "closed":false,"commentRequired":true,"ownerParticipates":false
    }}
    """
    let repository = withDependencies {
      $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
    } operation: {
      ClassRepositoryImpl()
    }

    #expect(try ClassroomService.detail(5).url().path == "/api/v1/classes/5")
    let room = try await repository.fetchClass(id: 5)
    #expect(room.id == 5)
    #expect(room.battleType == .custom)
    #expect(room.joinCode.isEmpty)
    #expect(room.role == .member)
    #expect(room.requiresComment)
    #expect(!room.ownerParticipates)
    #expect(room.deadline == .distantFuture)
  }
}

private struct ClassRecommendationStubClient: PickeNetworkClient {
  private struct Envelope<T: Decodable>: Decodable {
    struct Failure: Decodable {
      let code: String?
      let message: String?
    }

    let statusCode: Int?
    let data: T?
    let error: Failure?
  }

  let data: Data

  func send<T: Decodable & Sendable>(
    _: some PickeDataRequest,
    as _: T.Type
  ) async throws(PickeNetworkError) -> T {
    do {
      let envelope = try JSONDecoder().decode(Envelope<T>.self, from: data)
      if let failure = envelope.error {
        throw PickeNetworkError.response(
          ResponseError(httpStatus: envelope.statusCode ?? 400, code: failure.code, message: failure.message)
        )
      }
      guard let payload = envelope.data else { throw PickeNetworkError.decoding(.dataMissing) }
      return payload
    } catch let error as PickeNetworkError {
      throw error
    } catch {
      throw .decoding(.failed(error))
    }
  }

  func send<R: PickeDataRequest>(_ request: R) async throws(PickeNetworkError) -> R.Response {
    try await send(request, as: R.Response.self)
  }

  func sendResponse(_: some PickeDataRequest) async throws(PickeNetworkError) -> PickeHTTPResponse {
    PickeHTTPResponse(statusCode: 200, data: data)
  }

  func upload<R: PickeUploadRequest>(_: R) async throws(PickeNetworkError) -> R.Response {
    throw .decoding(.dataMissing)
  }

  func upload(_: some PickeFileUploadRequest) async throws(PickeNetworkError) {
    throw .decoding(.dataMissing)
  }
}
