import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassReportFeature.self)
public struct ClassReportView: View {
  @Bindable public var store: StoreOf<ClassReportFeature>
  private let previewContent: ClassReportPreviewContent?

  public init(store: StoreOf<ClassReportFeature>) {
    self.store = store
    previewContent = nil
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
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "내 배틀 리포트") {
        Image(systemName: "ellipsis")
          .font(.system(size: 20))
          .frame(width: 24, height: 24)
      }
      .foregroundStyle(.gray800)

      reportTitle()
        .padding(.top, 16)
      reportTabs()
        .padding(.top, 16)
      reportPages()
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
  }
}

private extension ClassReportView {
  @ViewBuilder
  func reportTitle() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text("참여완료").pickeBadge(.filled, size: .tag)
        Text("#\(store.room.battle.category.title)").pickeBadge(.filled, size: .tag)
      }
      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func reportTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassReportFeature.Tab.allCases, id: \.self) { tab in
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
    TabView(selection: Binding(
      get: { store.selectedTab },
      set: { send(.tabSelected($0)) }
    )) {
      ForEach(ClassReportFeature.Tab.allCases, id: \.self) { tab in
        ScrollView {
          reportContent(for: tab)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
        .tag(tab)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .never))
    .animation(.easeInOut(duration: 0.25), value: store.selectedTab)
  }

  @ViewBuilder
  func reportContent(for tab: ClassReportFeature.Tab) -> some View {
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
    reportCard(minHeight: showsFigmaPreview ? 204 : 0) {
      cardHeading("내 참여 요약", destination: .participation)
      voteAndActivitySummary()
    }
    reportCard(minHeight: showsFigmaPreview ? 148 : 0) {
      cardHeading("AI 리포트", destination: .feedback)
      if showsFigmaPreview {
        Text(previewText(.aiSummaryTitle))
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
        Text(previewText(.aiSummaryDetail))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
      } else {
        unavailableReport(
          title: "AI 리포트를 준비하고 있어요",
          message: "작성한 의견이 분석되면 이곳에서 확인할 수 있어요."
        )
      }
    }
    reportCard(minHeight: showsFigmaPreview ? 95 : 0) {
      cardHeading("선생님 피드백", destination: .feedback)
      if showsFigmaPreview {
        Text(previewText(.teacherSummary))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
      } else {
        unavailableReport(
          title: "선생님 피드백 데이터를 불러올 수 없어요",
          message: "선생님 피드백이 등록되면 이곳에서 확인할 수 있어요."
        )
      }
    }
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

  @ViewBuilder
  func voteAndActivitySummary() -> some View {
    if showsFigmaPreview {
      HStack(spacing: 8) {
        voteChoice("사전 선택", value: previewText(.initialChoice))
        VStack(spacing: 4) {
          Image(systemName: "arrow.right")
          Text("입장 변경").pretendardFont(family: .Regular, size: 12)
        }
        .foregroundStyle(.primary500)
        voteChoice("사후 선택", value: previewText(.finalChoice))
      }
      .frame(maxWidth: .infinity)
      HStack(spacing: 0) {
        activityCount(previewText(.commentCount), label: "댓글")
        activityCount(previewText(.replyCount), label: "대댓글")
        activityCount(previewText(.receivedLikeCount), label: "받은 좋아요")
      }
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
  func cardHeading(_ title: String, destination: ClassReportFeature.Tab? = nil) -> some View {
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
  private func figmaReportStore(tab: ClassReportFeature.Tab) -> StoreOf<ClassReportFeature> {
    var state = ClassReportFeature.State(room: .mocks[0])
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
