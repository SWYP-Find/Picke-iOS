//
//  MockClassOwnerDashboard.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum MockClassOwnerDashboard {
  public static let figma: ClassOwnerDashboardData = {
    var members = [
      ClassOwnerMember(id: 1, name: "김민지", participationCount: 8, needsReview: true),
      ClassOwnerMember(id: 2, name: "이서준", participationCount: 7),
      ClassOwnerMember(id: 3, name: "박지우", participationCount: 6),
      ClassOwnerMember(id: 4, name: "최유진", participationCount: 0),
      ClassOwnerMember(id: 5, name: "정다은", participationCount: 0),
      ClassOwnerMember(id: 6, name: "한도윤", participationCount: 0, needsReview: true),
    ]
    members += (7 ... 32).map { id in
      ClassOwnerMember(id: id, name: "희망 \(id)", participationCount: id < 32 ? 1 : 0)
    }
    let opinions = [
      ClassOwnerOpinion(
        id: 1,
        author: "김민지",
        text: "슬픔을 겉으로 드러내지 않는다고 해서 타인을 사랑하지 않는다고 판단할 수는 없다고 생각해요.",
        replyCount: 23,
        recommendationCount: 1340,
        createdAt: Date(timeIntervalSince1970: 1_780_000_300)
      ),
      ClassOwnerOpinion(
        id: 2,
        author: "이서준",
        text: "감정은 개인의 자유지만, 사회적 관계에서는 최소한의 공감 표현도 필요하다고 생각해요.",
        replyCount: 12,
        recommendationCount: 840,
        createdAt: Date(timeIntervalSince1970: 1_780_000_200)
      ),
      ClassOwnerOpinion(
        id: 3,
        author: "박지우",
        text: "교육과 보호도 함께 고려해야 한다고 생각합니다.",
        replyCount: 4,
        recommendationCount: 510,
        createdAt: Date(timeIntervalSince1970: 1_780_000_100)
      ),
    ]
    let insight = "처음에는 뫼르소의 태도를 비난할 수 있다는 의견이 많았지만, 대화 후에는 행동과 감정을 분리해서 봐야 한다는 의견이 늘어났어요."
    let baseReport = MockClassReport.figma
    var reportTexts = baseReport.texts
    reportTexts[.aiSummaryDetail] = insight
    reportTexts[.feedbackDetail1] = "처음에는 범죄에 대한 책임을 중요하게 봤지만, 대화를 거치며 재범을 줄이기 위한 교육과 보호의 역할도 함께 고려했어요."
    reportTexts[.feedbackDetail2] = "“처벌만으로는 해결되지 않는다”는 생각에서 한 걸음 더 나아가 교육과 보호라는 대안을 의견에 덧붙였어요."
    let report = ClassReport(
      texts: reportTexts,
      myOpinions: baseReport.myOpinions,
      initialVoteLeading: baseReport.initialVoteLeading,
      finalVoteLeading: baseReport.finalVoteLeading,
      layout: baseReport.layout
    )
    return ClassOwnerDashboardData(
      members: members,
      opinions: opinions,
      report: report,
      metrics: ClassParticipationMetrics(
        commentAuthorCount: 24,
        optionAVoteCount: 18,
        optionBVoteCount: 10
      ),
      insight: insight
    )
  }()
}
