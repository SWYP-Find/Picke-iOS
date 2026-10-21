@testable import ClassDomain
import ClassDomainInterface
import Dependencies
import Foundation
import PickeNetwork
import Testing

struct ClassRecommendationTests {
  @Test
  func 추천_요청은_수준과_카테고리와_검색어를_쿼리로_보낸다() throws {
    let request = ClassBattleRecommendationService.recommendations(
      filter: .init(keyword: "인간 자유", level: .high, categories: [.philosophy, .society])
    )
    let url = try request.url()
    let parameters = try #require(request.parameters)
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
  func 빈_추천_응답은_빈_목록이고_다른_클래스_기능은_목_저장소를_쓴다() async throws {
    let json = #"{"statusCode":200,"data":{"items":[]}}"#
    let live = ClassLiveRepository(
      mock: MockClassRepository(rooms: [ClassRoom.mocks[0]], availableRooms: []),
      recommendations: withDependencies {
        $0.networkClient = ClassRecommendationStubClient(data: Data(json.utf8))
      } operation: {
        ClassRepositoryImpl()
      }
    )

    #expect(try await live.fetchRecommendedBattles(filter: .init(category: .philosophy)).isEmpty)
    #expect(try await live.fetchMyClasses().map(\.id) == [ClassRoom.mocks[0].id])
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
