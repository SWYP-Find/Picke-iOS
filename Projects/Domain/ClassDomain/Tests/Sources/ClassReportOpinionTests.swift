//
//  ClassReportOpinionTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/17/26.
//

import ClassDomainInterface
import Testing

struct ClassReportOpinionTests {
  @Test
  func legacyEntriesPreserveDuplicateBodiesAndTheirOrder() {
    let report = makeReport(myOpinions: ["same", "same", "other"])
    #expect(report.opinionEntries == nil)
    #expect(report.resolvedOpinions.map(\.id) == ["legacy-0", "legacy-1", "legacy-2"])
    #expect(report.resolvedOpinions.map(\.body) == ["same", "same", "other"])
    #expect(report.resolvedOpinions.allSatisfy { $0.kind == .unspecified })
    #expect(report.resolvedOpinions.allSatisfy { $0.stance == nil && $0.likeCount == nil && $0.parent == nil })
  }

  @Test
  func structuredEntriesAreAuthoritativeEvenWhenEmptyOrConflicting() {
    let empty = makeReport(myOpinions: ["legacy"], opinionEntries: [])
    #expect(empty.resolvedOpinions.isEmpty)

    let entries = [
      ClassReportOpinion(id: "repeated", kind: .comment, body: "new"),
      ClassReportOpinion(id: "repeated", kind: .reply, body: "new"),
    ]
    let conflicting = makeReport(myOpinions: ["legacy"], opinionEntries: entries)
    #expect(conflicting.resolvedOpinions == entries)
    #expect(conflicting.resolvedOpinions.count == 2)
  }

  @Test
  func figmaCaptureHasFiveEntriesAndIndependentActivityTotals() {
    let report = MockClassReport.figmaMyOpinions
    #expect(report.resolvedOpinions.map(\.kind) == [.comment, .reply, .reply, .reply, .reply])
    #expect(report.resolvedOpinions.count == 5)
    #expect(report[.commentCount] == "1")
    #expect(report[.replyCount] == "4")
    #expect(report.resolvedOpinions[0].likeCount == 1340)
    #expect(report.resolvedOpinions[0].replyCount == 23)
    #expect(report.resolvedOpinions[0].body == "\(report.resolvedOpinions[1].body) \(report.resolvedOpinions[1].body)")
    #expect(report.resolvedOpinions.dropFirst().allSatisfy { $0.parent?.body.isEmpty == false })
  }

  private func makeReport(
    myOpinions: [String],
    opinionEntries: [ClassReportOpinion]? = nil
  ) -> ClassReport {
    ClassReport(
      texts: [:],
      myOpinions: myOpinions,
      initialVoteLeading: 0,
      finalVoteLeading: 0,
      layout: .summary,
      opinionEntries: opinionEntries
    )
  }
}
