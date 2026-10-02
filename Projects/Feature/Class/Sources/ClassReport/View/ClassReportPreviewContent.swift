import CoreGraphics

struct ClassReportPreviewContent {
  enum Key: Hashable {
    case aiSummaryTitle, aiSummaryDetail, teacherSummary
    case commentStance, commentDate, commentBody, commentLikes, commentReplies
    case replyAuthor, replyParent, replyBody, replyDate, replyLikes
    case participantTitle, participantCount, classSummary
    case bestAuthor, bestBody, bestLikes, bestReplies
    case feedbackTitle1, feedbackDetail1, feedbackTitle2, feedbackDetail2
    case feedbackTitle3, feedbackDetail3, nextQuestion, nextHint
    case teacherFeedback, teacherName, teacherDate
    case initialChoice, finalChoice, commentCount, replyCount, receivedLikeCount
  }

  let texts: [Key: String]
  let initialVoteLeading: CGFloat
  let finalVoteLeading: CGFloat

  subscript(_ key: Key) -> String {
    texts[key] ?? ""
  }
}

#if DEBUG
  extension ClassReportPreviewContent {
    static let figma = Self(
      texts: [
        .aiSummaryTitle: "다른 해결방법까지 생각을 확장했어요",
        .aiSummaryDetail: "“교육과 보호도 함께 필요하다”는 대댓글에서 처벌 외의 대안을 제시했어요",
        .teacherSummary: "“왜 생각이 달라졌는지 자신의 말로 설명한 점이 좋았어요”",
        .commentStance: "낮춰야한다",
        .commentDate: "26.09.23. 14:02",
        .commentBody: "제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요. 네덜란드 사례를 보면 우려가 현실이 되고 있죠.",
        .commentLikes: "1,340",
        .commentReplies: "23",
        .replyAuthor: "김민지 · 교정이 우선이다",
        .replyParent: "제도화가 무서운 건, 사회적 압력이 '선택'을 '의무'로 바꿀 수 있다는 거예요.",
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
        .feedbackTitle1: "내 생각의 변화를 설명했어요",
        .feedbackDetail1: "“처벌만으로는 해결되지 않는 점”을 언급하며, 처음과 입장이 달리진 이유를 드러냈어요.",
        .feedbackTitle2: "다른 해결방법을 제안했어요",
        .feedbackDetail2: "반대의견에 그치지 않고 “교육과 보호”라는 대안을 덧붙였어요.",
        .feedbackTitle3: "근거를 한 단계 더 구체적으로",
        .feedbackDetail3: "교육과 보호가 재범을 줄이는 데 어떤 도움이 되는지, 사례나 자료 하나를 연결하면 주장이 더 설득력 있어져요.",
        .nextQuestion: "처벌과 교화를 함께 한다면,\n무엇을 기준으로 균형을 잡을까요?",
        .nextHint: "내 의견과 반대되는 입장도 함께 떠올려 보세요.",
        .teacherFeedback: "처음과 나중의 생각이 어떻게 달라졌는지 스스로 정리한 점이 좋았어요. 단순히 입장을 바꾸는 데서 끝나지 않고, 왜 바뀌었는지 설명하려는 태도가 인상적이었습니다.",
        .teacherName: "김민지 선생님",
        .teacherDate: "26.09.23. 14:02",
        .initialChoice: "낮춰야 한다",
        .finalChoice: "교정이 우선이다",
        .commentCount: "1",
        .replyCount: "12",
        .receivedLikeCount: "8",
      ],
      initialVoteLeading: 0.64,
      finalVoteLeading: 0.50
    )
  }
#endif
