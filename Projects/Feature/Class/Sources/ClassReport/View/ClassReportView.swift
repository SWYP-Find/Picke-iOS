import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassReportFeature.self)
public struct ClassReportView: View {
  @Bindable public var store: StoreOf<ClassReportFeature>
  private let previewContent: ClassReportPreviewContent?

  public init(store: StoreOf<ClassReportFeature>) {
    self.store = store
    previewContent = [ClassRoom.mockJoinable, .mockClosedSociety].contains { previewRoom in
      store.room.joinCode == previewRoom.joinCode
        && store.room.name == previewRoom.name
        && store.room.battle == previewRoom.battle
    } ? .figma : nil
  }

  #if DEBUG
    init(store: StoreOf<ClassReportFeature>, previewContent: ClassReportPreviewContent) {
      self.store = store
      self.previewContent = previewContent
    }
  #endif

  private var showsFigmaPreview: Bool {
    previewContent != nil
  }

  private func previewText(_ key: ClassReportPreviewContent.Key) -> String {
    previewContent?[key] ?? ""
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name) {
        Button { send(.backTapped) } label: {
          Image(systemName: "xmark")
            .font(.system(size: 20, weight: .light))
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
      }
      .foregroundStyle(.gray800)

      reportTitle()
        .padding(.top, 16)
      reportPages()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassReportView {
  @ViewBuilder
  func reportTitle() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text(store.room.status == .closed || showsFigmaPreview ? "마감" : "진행 중")
          .pickeBadge(.filled, size: .tag)
        Text("#\(store.room.battle.categoryDisplayTitle)").pickeBadge(.filled, size: .tag)
      }
      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .lineLimit(2)
      Text(store.room.deadline == .distantFuture
        ? "마감일 없음"
        : store.room.deadline.formatted(.dottedDateTimeWithWeekday) + "까지")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func reportTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassReportTab.allCases, id: \.self) { tab in
        Button { send(.tabSelected(tab)) } label: {
          Text(tab.rawValue)
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(store.selectedTab == tab ? .primary500 : .gray300)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay(alignment: .bottom) {
              Rectangle()
                .fill(store.selectedTab == tab ? .primary500 : .gray100)
                .frame(height: store.selectedTab == tab ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  func reportPages() -> some View {
    if showsFigmaPreview {
      reportPage(for: .summary)
    } else {
      TabView(selection: $store.selectedTab.sending(\.view.tabSelected)) {
        ForEach(ClassReportTab.allCases, id: \.self) { tab in
          reportPage(for: tab)
            .tag(tab)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .animation(.easeInOut(duration: 0.25), value: store.selectedTab)
    }
  }

  func reportPage(for tab: ClassReportTab) -> some View {
    ScrollView {
      VStack(spacing: 0) {
        if tab != .summary {
          reportTabs().padding(.top, 16)
        }
        reportContent(for: tab)
          .padding(.horizontal, 16)
          .padding(.top, 16)
          .padding(.bottom, 16)
      }
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  func reportContent(for tab: ClassReportTab) -> some View {
    VStack(spacing: 16) {
      switch tab {
      case .summary:
        summaryContent()
      case .participation:
        participationContent()
      case .classResult:
        classResultContent()
      case .feedback:
        feedbackContent()
      }
    }
  }

  @ViewBuilder
  func summaryContent() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 12) {
        sectionHeading("내 투표 결과")
        reportCard(minHeight: showsFigmaPreview ? 136 : 0) {
          voteAndActivitySummary()
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        sectionHeading("AI 피드백")
        reportCard(padding: 0, spacing: 0, minHeight: showsFigmaPreview ? 350 : 0) {
          if showsFigmaPreview {
            aiFeedbackSummary()
          } else {
            unavailableReport(
              title: "AI 피드백을 준비하고 있어요",
              message: "작성한 의견이 분석되면 이곳에서 확인할 수 있어요."
            )
            .padding(16)
          }
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        sectionHeading("다음 생각 해보기")
        VStack(alignment: .leading, spacing: 12) {
          Text(showsFigmaPreview ? previewText(.nextQuestion) : store.room.battle.title)
            .pretendardFont(family: .SemiBold, size: 18)
            .foregroundStyle(.gray800)
          Text(showsFigmaPreview ? previewText(.nextHint) : "내 의견과 반대되는 입장도 함께 떠올려 보세요.")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.beige100, in: RoundedRectangle(cornerRadius: 2))
      }

      if !showsFigmaPreview {
        HStack(spacing: 8) {
          reportPageLink("참여 기록", tab: .participation)
          reportPageLink("클래스 결과", tab: .classResult)
          reportPageLink("피드백", tab: .feedback)
        }
      }
    }
  }

  func reportPageLink(_ title: String, tab: ClassReportTab) -> some View {
    Button { send(.tabSelected(tab)) } label: {
      Text(title)
        .pickeSortChip(isSelected: false)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  func participationContent() -> some View {
    reportCard(minHeight: showsFigmaPreview ? 204 : 0) {
      cardHeading("내 투표 결과")
      voteAndActivitySummary()
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 177 : 0) {
      cardHeading("내 댓글")
      if showsFigmaPreview {
        HStack {
          Text(previewText(.commentStance)).pickeBadge(.filled, size: .tag)
          Spacer()
          Text(previewText(.commentDate)).pretendardFont(family: .Regular, size: 12).foregroundStyle(.gray300)
        }
        Text(previewText(.commentBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        reactions(likes: previewText(.commentLikes), replies: previewText(.commentReplies))
      } else {
        unavailableReport(
          title: "댓글 데이터를 불러올 수 없어요",
          message: "댓글 데이터가 연결되면 이곳에서 확인할 수 있어요."
        )
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 225 : 0) {
      cardHeading("내 대댓글")
      if showsFigmaPreview {
        Text(previewText(.replyAuthor))
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
        Text(previewText(.replyParent))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        Rectangle().fill(.beige600).frame(height: 1)
        Text("내 대댓글").pretendardFont(.semiBold13).foregroundStyle(.gray800)
        Text(previewText(.replyBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        HStack {
          Text(previewText(.replyDate))
          Spacer()
          Image(systemName: "heart")
          Text(previewText(.replyLikes))
        }
        .pretendardFont(family: .Regular, size: 12)
        .foregroundStyle(.gray300)
      } else {
        unavailableReport(
          title: "대댓글 데이터를 불러올 수 없어요",
          message: "대댓글 데이터가 연결되면 이곳에서 확인할 수 있어요."
        )
      }
    }
  }

  @ViewBuilder
  func classResultContent() -> some View {
    reportCard(minHeight: showsFigmaPreview ? 243 : 0) {
      cardHeading("우리 클래스 참여 현황")
      HStack {
        Text(showsFigmaPreview ? previewText(.participantTitle) : "클래스 멤버")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
        Spacer()
        Text(showsFigmaPreview ? previewText(.participantCount) : "\(store.room.memberCount)명")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
      }
      if showsFigmaPreview {
        voteDistribution(title: "사전 투표 결과", leading: previewContent?.initialVoteLeading ?? 0)
        voteDistribution(title: "사후 투표 결과", leading: previewContent?.finalVoteLeading ?? 0)
      } else {
        unavailableReport(
          title: "투표 분포를 집계할 수 없어요",
          message: "현재 클래스 데이터에는 투표 집계가 포함되어 있지 않아요."
        )
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 120 : 0) {
      cardHeading("클래스 결과 요약")
      if showsFigmaPreview {
        Text(previewText(.classSummary))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
      } else {
        Text("\(store.room.battle.optionATitle)\n\(store.room.battle.optionBTitle)")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        Text("두 선택지에 대한 클래스 투표 결과가 연결되면 비교해 드릴게요.")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 142 : 0) {
      cardHeading("BEST 댓글")
      if showsFigmaPreview {
        Text(previewText(.bestAuthor))
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
        Text(previewText(.bestBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        reactions(likes: previewText(.bestLikes), replies: previewText(.bestReplies))
      } else {
        unavailableReport(
          title: "BEST 댓글 데이터를 불러올 수 없어요",
          message: "댓글 반응 데이터가 연결되면 가장 많은 공감을 받은 댓글을 보여드릴게요."
        )
      }
    }
  }

  @ViewBuilder
  func feedbackContent() -> some View {
    reportCard(minHeight: showsFigmaPreview ? 361 : 0) {
      cardHeading("AI 피드백")
      if showsFigmaPreview {
        feedbackPoint(previewText(.feedbackTitle1), detail: previewText(.feedbackDetail1))
        feedbackPoint(previewText(.feedbackTitle2), detail: previewText(.feedbackDetail2))
        feedbackPoint(previewText(.feedbackTitle3), detail: previewText(.feedbackDetail3))
        Text("분석에 사용한 내 대댓글 보기")
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
      } else {
        unavailableReport(
          title: "AI 분석 결과가 아직 없어요",
          message: "내 의견과 댓글 데이터가 연결되면 생각의 변화와 근거를 분석해 드릴게요."
        )
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 138 : 0) {
      cardHeading("다음 생각 해보기")
      Text(showsFigmaPreview ? previewText(.nextQuestion) : store.room.battle.title)
        .pretendardFont(family: .SemiBold, size: 18)
        .foregroundStyle(.gray700)
      Text(showsFigmaPreview ? previewText(.nextHint) : "두 선택지를 비교하며 내 생각을 정리해 보세요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    reportCard(padding: 16, spacing: 8, minHeight: showsFigmaPreview ? 142 : 0) {
      cardHeading("선생님 피드백")
      if showsFigmaPreview {
        Text(previewText(.teacherFeedback))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        HStack {
          Text(previewText(.teacherName))
          Spacer()
          Text(previewText(.teacherDate))
        }
        .pretendardFont(family: .Regular, size: 12)
        .foregroundStyle(.gray300)
      } else {
        unavailableReport(
          title: "선생님 피드백 데이터를 불러올 수 없어요",
          message: "선생님이 피드백을 남기면 이곳에서 확인할 수 있어요."
        )
      }
    }
  }

  func sectionHeading(_ title: String) -> some View {
    Text(title)
      .pretendardFont(.semiBold15)
      .foregroundStyle(.gray800)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func aiFeedbackSummary() -> some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 8) {
        ClassAIInsightHeading(title: "내 판단의 기준")
        Text(previewText(.aiSummaryDetail))
          .pretendardFont(.regular13)
      }
      .foregroundStyle(.primary500)
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.primary50)

      VStack(alignment: .leading, spacing: 16) {
        insightPoint(
          "이번에 잘한 점",
          detail: previewText(.feedbackDetail1)
        )
        Rectangle().fill(.beige600).frame(height: 1)
        insightPoint(
          "한 가지 더 살펴볼 점",
          detail: previewText(.feedbackDetail2)
        )
        Rectangle().fill(.beige600).frame(height: 1)
        insightPoint(
          "다음 생각 한 걸음",
          detail: previewText(.feedbackDetail3)
        )
        Rectangle().fill(.beige600).frame(height: 1)
        Button { send(.myOpinionsTapped) } label: {
          HStack {
            Text("내가 남긴 의견 \(previewContent?.myOpinions.count ?? 0)개 보기")
            Spacer()
            Image(systemName: store.showsMyOpinions ? "chevron.up" : "chevron.right")
          }
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
        }
        .buttonStyle(.plain)
        if store.showsMyOpinions {
          ForEach(previewContent?.myOpinions ?? [], id: \.self) { opinion in
            Text(opinion)
              .pretendardFont(.regular13)
              .foregroundStyle(.gray700)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(12)
              .background(.beige100, in: RoundedRectangle(cornerRadius: 2))
          }
        }
      }
      .padding(16)
    }
  }

  func insightPoint(_ label: String, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(label)
        .pretendardFont(.semiBold13)
        .foregroundStyle(.primary500)
      Text(detail)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray800)
    }
  }

  @ViewBuilder
  func voteAndActivitySummary() -> some View {
    if showsFigmaPreview {
      HStack(spacing: 8) {
        voteChoice("사전 선택", value: previewText(.initialChoice))
        VStack(spacing: 4) {
          Text("입장 변경")
            .pretendardFont(family: .SemiBold, size: 12)
            .foregroundStyle(.beige50)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.primary500, in: Capsule())
        }
        voteChoice("사후 선택", value: previewText(.finalChoice))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(.beige100, in: RoundedRectangle(cornerRadius: 2))
      HStack(spacing: 0) {
        activityCount(previewText(.commentCount), label: "댓글")
        Rectangle().fill(.beige600).frame(width: 1, height: 36)
        activityCount(previewText(.replyCount), label: "대댓글")
        Rectangle().fill(.beige600).frame(width: 1, height: 36)
        activityCount(previewText(.receivedLikeCount), label: "받은 추천")
      }
      .padding(.vertical, 4)
    } else {
      unavailableReport(
        title: "내 투표와 참여 기록을 불러올 수 없어요",
        message: "리포트 데이터가 연결되면 이곳에서 확인할 수 있어요."
      )
    }
  }

  func voteChoice(_ title: String, value: String) -> some View {
    VStack(spacing: 4) {
      Text(title).pretendardFont(family: .Regular, size: 12).foregroundStyle(.gray300)
      Text(value).pretendardFont(.semiBold13).foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity)
  }

  func activityCount(_ count: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(count).pretendardFont(family: .SemiBold, size: 18).foregroundStyle(.gray800)
      Text(label).pretendardFont(.regular13).foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  func reactions(likes: String, replies: String) -> some View {
    HStack(spacing: 16) {
      Label(likes, systemImage: "heart")
      Label(replies, systemImage: "bubble.right")
    }
    .pretendardFont(.regular13)
    .foregroundStyle(.gray300)
  }

  func voteDistribution(title: String, leading: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).pretendardFont(.regular13).foregroundStyle(.gray700)
      GeometryReader { geometry in
        HStack(spacing: 0) {
          Rectangle().fill(Color.primary500).frame(width: geometry.size.width * leading)
          Rectangle().fill(Color.gray300)
        }
      }
      .frame(height: 8)
      HStack {
        Text(store.room.battle.optionATitle)
        Spacer()
        Text(store.room.battle.optionBTitle)
      }
      .pretendardFont(.regular13)
      .foregroundStyle(.gray700)
    }
  }

  func feedbackPoint(_ title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.primary500)
      VStack(alignment: .leading, spacing: 4) {
        Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
        Text(detail).pretendardFont(.regular13).foregroundStyle(.gray700)
      }
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  func reportCard(
    padding: CGFloat = 12,
    spacing: CGFloat = 12,
    minHeight: CGFloat = 0,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: spacing, content: content)
      .padding(.vertical, padding)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(minHeight: minHeight, alignment: .top)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func cardHeading(_ title: String, destination: ClassReportTab? = nil) -> some View {
    HStack {
      Text(title)
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)
      Spacer(minLength: 0)
      if let destination {
        Button { send(.tabSelected(destination)) } label: {
          HStack(spacing: 4) {
            Text("보기")
              .pretendardFont(family: .Bold, size: 12)
            Image(systemName: "chevron.right")
              .font(.system(size: 10, weight: .semibold))
          }
          .foregroundStyle(.primary500)
        }
        .buttonStyle(.plain)
      }
    }
    .frame(height: 39)
  }

  @ViewBuilder
  func unavailableReport(title: String, message: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .pretendardFont(.semiBold15)
        .foregroundStyle(.gray800)
      Text(message)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
  }
}

#if DEBUG
  private func figmaReportStore(tab: ClassReportTab) -> StoreOf<ClassReportFeature> {
    let room = ClassRoom.mocks[0]
    let battle = ClassBattleSummary(
      id: room.battle.id,
      title: room.battle.title,
      summary: room.battle.summary,
      thumbnailURL: room.battle.thumbnailURL,
      philosopherA: room.battle.philosopherA,
      optionATitle: "낮춰야 한다",
      optionADescription: room.battle.optionADescription,
      philosopherAImageURL: room.battle.philosopherAImageURL,
      philosopherB: room.battle.philosopherB,
      optionBTitle: "교정이 우선이다",
      optionBDescription: room.battle.optionBDescription,
      philosopherBImageURL: room.battle.philosopherBImageURL,
      category: room.battle.category,
      categoryDisplayTitle: room.battle.categoryDisplayTitle,
      level: room.battle.level,
      audioDuration: room.battle.audioDuration,
      viewCount: room.battle.viewCount
    )
    let completedRoom = ClassRoom(
      id: room.id,
      name: room.name,
      joinCode: room.joinCode,
      battle: battle,
      deadline: room.deadline,
      memberCount: room.memberCount,
      role: .member,
      status: .closed,
      allowsAnonymousOpinion: room.allowsAnonymousOpinion,
      requiresComment: room.requiresComment
    )
    var state = ClassReportFeature.State(room: completedRoom)
    state.selectedTab = tab
    return Store(initialState: state) { ClassReportFeature() }
  }

  #Preview("리포트 · 요약") {
    ClassReportView(store: figmaReportStore(tab: .summary), previewContent: .figma)
  }

  #Preview("리포트 · 내 참여") {
    ClassReportView(store: figmaReportStore(tab: .participation), previewContent: .figma)
  }

  #Preview("리포트 · 클래스 결과") {
    ClassReportView(store: figmaReportStore(tab: .classResult), previewContent: .figma)
  }

  #Preview("리포트 · 피드백") {
    ClassReportView(store: figmaReportStore(tab: .feedback), previewContent: .figma)
  }
#endif
