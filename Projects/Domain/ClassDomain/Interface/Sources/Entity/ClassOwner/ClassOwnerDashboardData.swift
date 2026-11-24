//
//  ClassOwnerDashboardData.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public struct ClassOwnerDashboardData: Equatable, Sendable {
  public let members: [ClassOwnerMember]
  public let opinions: [ClassOwnerOpinion]
  public let insight: String?
  public let report: ClassReport?
  public let metrics: ClassParticipationMetrics?

  public init(
    members: [ClassOwnerMember],
    opinions: [ClassOwnerOpinion],
    report: ClassReport?,
    metrics: ClassParticipationMetrics?,
    insight: String? = nil
  ) {
    self.members = members
    self.opinions = opinions
    self.report = report
    self.metrics = metrics
    self.insight = insight
  }
}
