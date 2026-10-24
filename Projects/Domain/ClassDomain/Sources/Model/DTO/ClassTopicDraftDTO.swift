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

  func toDomain() -> ClassTopicCandidate {
    ClassTopicCandidate(
      id: candidateId,
      question: question,
      description: description,
      category: category,
      difficulty: difficulty,
      options: options.map {
        .init(label: $0.label, rationale: $0.rationale, philosopher: $0.philosopher)
      }
    )
  }
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

  func toDomain() -> ClassTopicVersion {
    ClassTopicVersion(
      id: topicVersionId,
      draftID: draftId,
      versionNo: versionNo,
      source: source,
      question: question,
      description: description,
      category: category,
      difficulty: difficulty,
      options: options.map {
        .init(
          position: $0.position,
          label: $0.label,
          rationale: $0.rationale,
          philosopher: $0.philosopher,
          philosopherName: $0.philosopherName,
          philosopherImageKey: $0.philosopherImageKey
        )
      }
    )
  }
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

  func toDomain() -> ClassTopicDraft {
    ClassTopicDraft(
      id: draftId,
      topicSeed: topicSeed,
      difficulty: difficulty,
      categories: categories,
      suggestStatus: suggestStatus,
      clarificationMessage: clarificationMessage,
      batchNo: batchNo,
      remainingSuggestions: remainingSuggestions,
      remainingValidations: remainingValidations,
      candidates: candidates.map { $0.toDomain() },
      latestVersion: latestVersion?.toDomain()
    )
  }
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

  func toDomain() -> ClassTopicValidation {
    ClassTopicValidation(
      valid: valid,
      issues: issues.map { .init(field: $0.field, code: $0.code, message: $0.message) },
      validatedTopicVersionID: validatedTopicVersionId,
      remainingValidations: remainingValidations,
      version: version?.toDomain()
    )
  }
}
