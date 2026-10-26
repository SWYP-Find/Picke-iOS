import ClassDomainInterface
import Foundation

extension ClassTopicCandidateDTO {
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

extension ClassTopicVersionDTO {
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

extension ClassTopicDraftDTO {
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

extension ClassTopicValidationDTO {
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
