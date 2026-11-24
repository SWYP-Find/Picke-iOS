import ClassDomainInterface
import Foundation

struct ClassTopicCandidateDTO: Decodable, Sendable {
  struct Option: Decodable, Sendable {
    let label: String
    let rationale: String
    let philosopher: String?
  }

  let candidateId: Int
  let question: String
  let description: String
  let category: String
  let difficulty: String
  let options: [Option]
}

struct ClassTopicVersionDTO: Decodable, Sendable {
  struct Option: Decodable, Sendable {
    let position: String
    let label: String
    let rationale: String
    let philosopher: String?
    let philosopherName: String?
    let philosopherImageKey: String?
  }

  let topicVersionId: Int
  let draftId: Int
  let versionNo: Int
  let source: String
  let question: String
  let description: String
  let category: String
  let difficulty: String
  let options: [Option]
}

struct ClassTopicDraftDTO: Decodable, Sendable {
  let draftId: Int
  let topicSeed: String
  let difficulty: String
  let categories: [String]
  let suggestStatus: String
  let clarificationMessage: String?
  let batchNo: Int
  let remainingSuggestions: Int
  let remainingValidations: Int
  let candidates: [ClassTopicCandidateDTO]
  let latestVersion: ClassTopicVersionDTO?
}

struct ClassTopicValidationDTO: Decodable, Sendable {
  struct Issue: Decodable, Sendable {
    let field: String
    let code: String
    let message: String
  }

  let valid: Bool
  let issues: [Issue]
  let validatedTopicVersionId: Int?
  let remainingValidations: Int
  let version: ClassTopicVersionDTO?
}
