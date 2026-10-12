//
//  MockClassReport.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum MockClassReport {
  public static let figma = ClassReport(
    texts: [
      .aiSummaryTitle: "이번 토론에서 생각의 기준이 넓어졌어요",
      .aiSummaryDetail: "마지막 의견에서는 재범을 줄이는 방법으로 교육과 보호를 중요하게 봤어요.",
      .teacherSummary: "“왜 생각이 달라졌는지 자신의 말로 설명한 점이 좋았어요”",
      .commentStance: "낮춰야한다",
      .commentDate: "26.09.23. 14:02",
      .commentBody: "촉법소년 연령을 낮추는 것만으로는 재범을 막기 어려워요. 피해자를 보호하면서 교육과 교정도 함께 해야 한다고 생각해요.",
      .commentLikes: "1,340",
      .commentReplies: "23",
      .replyAuthor: "김민지 · 교정이 우선이다",
      .replyParent: "촉법소년 연령을 낮추는 것만으로는 재범을 막기 어려워요.",
      .replyBody: "토론을 들으면서 처벌만으로는 해결되지 않는 점을 이해하게 됐어요. 교육과 보호도 함께 필요하다고 생각해요.",
      .replyDate: "26.09.23. 14:02",
      .replyLikes: "12",
      .participantTitle: "참여한 학생",
      .participantCount: "28 / 32",
      .classSummary: "입장을 바꾼 학생은 6명이에요.\n연령하향 → 교정우선 5명, 교정 우선 → 연령 하향 1명이에요.\n교정 우선 선택은 10명에서 14명으로 늘었어요.",
      .bestAuthor: "김민지 · 교정이 우선이다",
      .bestBody: "“피해자 보호를 위한 기준도 함께 필요하지 않을까요?”",
      .bestLikes: "1,340",
      .bestReplies: "23",
      .feedbackTitle1: "처벌의 필요성에서 교정 가능성까지 함께 보기 시작했어요",
      .feedbackDetail1: "“처벌만으로는 해결되지 않는다”는 반대 의견에 그치지 않고, 교육과 보호라는 대안을 제시했어요. 해결 방법까지 논의를 이어 간 점이 좋았어요.",
      .feedbackTitle2: "반대하는 데서 끝나지 않고 다른 해결 방향을 제시했어요",
      .feedbackDetail2: "교육과 보호가 어떤 상황에서 효과적일지는 아직 설명되지 않았어요. 대안을 제시한 만큼, 그 대안이 효과를 낼 조건을 덧붙이면 주장이 더 분명해져요.",
      .feedbackTitle3: "근거를 한 단계 더 구체적으로",
      .feedbackDetail3: "교육과 보호가 재범을 줄이려면, 어떤 조건이 가장 먼저 갖춰져야 할까요?",
      .nextQuestion: "처벌과 교화를 함께 한다면,\n무엇을 기준으로 균형을 잡을까요?",
      .nextHint: "내 의견과 반대되는 입장도 함께 떠올려 보세요.",
      .teacherFeedback: "처음과 나중의 생각이 어떻게 달라졌는지 스스로 정리한 점이 좋았어요. 단순히 입장을 바꾸는 데서 끝나지 않고, 왜 바뀌었는지 설명하려는 태도가 인상적이었습니다.",
      .teacherName: "김민지 선생님",
      .teacherDate: "26.09.23. 14:02",
      .initialChoice: "낮춰야 한다",
      .finalChoice: "교정이 우선이다",
      .commentCount: "2",
      .replyCount: "3",
      .receivedLikeCount: "12",
    ],
    myOpinions: [
      "처벌만으로 문제를 해결하기보다 교육과 보호의 역할도 함께 생각해야 한다고 봐요.",
      "피해자의 안전을 지키면서도 다시 같은 일이 일어나지 않게 도울 방법이 필요해요.",
      "토론을 들으며 연령만 낮추는 것보다 교정의 기준을 세우는 일이 중요하다고 느꼈어요.",
    ],
    initialVoteLeading: 0.64,
    finalVoteLeading: 0.50,
    layout: .summary
  )
}
