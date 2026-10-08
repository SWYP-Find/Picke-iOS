import ClassDomainInterface
import Foundation

#if canImport(FoundationModels)
  import FoundationModels

  @available(iOS 26.0, *)
  actor ClassAIChatFoundationEngine {
    static let shared = ClassAIChatFoundationEngine()

    private var sessions: [UUID: LanguageModelSession] = [:]
    private var respondingIDs: Set<UUID> = []

    func start(id: UUID, stance: String, opponent: String) throws {
      let model = SystemLanguageModel.default
      guard case .available = model.availability else {
        throw ClassAIChatError.unavailable
      }
      guard model.supportsLocale(Locale(identifier: "ko_KR")) else {
        throw ClassAIChatError.unsupportedLanguage
      }
      let instructions = """
      당신은 클래스 토론의 상대 철학자 \(opponent)입니다. 사용자는 '\(stance)' 입장을 골랐습니다.
      한국어로만 답하고, 사용자의 의견에 정중하게 반박하세요. 철학자의 관점을 유지하되 역사적 인용을 꾸며내지 마세요.
      한 차례 답변은 짧은 문장 1~3개, 총 240자 이내로 작성하세요. 질문이나 반론으로 끝내세요.
      """
      let session = LanguageModelSession(model: model, instructions: instructions)
      session.prewarm()
      sessions[id] = session
    }

    func respond(id: UUID, text: String) async throws -> String {
      guard let session = sessions[id] else { throw ClassAIChatError.noSession }
      guard !respondingIDs.contains(id) else { throw ClassAIChatError.alreadyResponding }
      respondingIDs.insert(id)
      defer { respondingIDs.remove(id) }
      let response = try await session.respond(to: text)
      return String(response.content.prefix(600))
    }

    func end(id: UUID) {
      sessions[id] = nil
      respondingIDs.remove(id)
    }
  }
#endif
