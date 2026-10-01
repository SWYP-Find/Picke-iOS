import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassReportFeature.self)
public struct ClassReportView: View {
  public let store: StoreOf<ClassReportFeature>

  public init(store: StoreOf<ClassReportFeature>) {
    self.store = store
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
    reportCard {
      cardHeading("내 참여 요약", destination: .participation)
      unavailableReport(
        title: "내 투표와 참여 기록을 불러올 수 없어요",
        message: "리포트 데이터가 연결되면 이곳에서 확인할 수 있어요."
      )
    }
    reportCard {
      cardHeading("AI 리포트", destination: .feedback)
      unavailableReport(
        title: "AI 리포트를 준비하고 있어요",
        message: "작성한 의견이 분석되면 이곳에서 확인할 수 있어요."
      )
    }
    reportCard {
      cardHeading("선생님 피드백", destination: .feedback)
      unavailableReport(
        title: "선생님 피드백 데이터를 불러올 수 없어요",
        message: "선생님 피드백이 등록되면 이곳에서 확인할 수 있어요."
      )
    }
  }

  @ViewBuilder
  func participationContent() -> some View {
    reportCard {
      cardHeading("내 투표 결과")
      unavailableReport(
        title: "내 투표 결과를 불러올 수 없어요",
        message: "이 클래스의 투표 결과가 연결되면 표시할게요."
      )
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("내 댓글")
      unavailableReport(
        title: "댓글 데이터를 불러올 수 없어요",
        message: "댓글 데이터가 연결되면 이곳에서 확인할 수 있어요."
      )
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("내 대댓글")
      unavailableReport(
        title: "대댓글 데이터를 불러올 수 없어요",
        message: "대댓글 데이터가 연결되면 이곳에서 확인할 수 있어요."
      )
    }
  }

  @ViewBuilder
  func classResultContent() -> some View {
    reportCard {
      cardHeading("우리 클래스 참여 현황")
      HStack {
        Text("클래스 멤버")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
        Spacer()
        Text("\(store.room.memberCount)명")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
      }
      unavailableReport(
        title: "투표 분포를 집계할 수 없어요",
        message: "현재 클래스 데이터에는 투표 집계가 포함되어 있지 않아요."
      )
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("클래스 결과 요약")
      Text("\(store.room.battle.optionATitle)\n\(store.room.battle.optionBTitle)")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      Text("두 선택지에 대한 클래스 투표 결과가 연결되면 비교해 드릴게요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("BEST 댓글")
      unavailableReport(
        title: "BEST 댓글 데이터를 불러올 수 없어요",
        message: "댓글 반응 데이터가 연결되면 가장 많은 공감을 받은 댓글을 보여드릴게요."
      )
    }
  }

  @ViewBuilder
  func feedbackContent() -> some View {
    reportCard {
      cardHeading("AI 피드백")
      unavailableReport(
        title: "AI 분석 결과가 아직 없어요",
        message: "내 의견과 댓글 데이터가 연결되면 생각의 변화와 근거를 분석해 드릴게요."
      )
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("다음 생각 해보기")
      Text(store.room.battle.title)
        .pretendardFont(family: .SemiBold, size: 18)
        .foregroundStyle(.gray700)
      Text("두 선택지를 비교하며 내 생각을 정리해 보세요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("선생님 피드백")
      unavailableReport(
        title: "선생님 피드백 데이터를 불러올 수 없어요",
        message: "선생님이 피드백을 남기면 이곳에서 확인할 수 있어요."
      )
    }
  }

  @ViewBuilder
  func reportCard(
    padding: CGFloat = 12,
    spacing: CGFloat = 12,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: spacing, content: content)
      .padding(.vertical, padding)
      .padding(.horizontal, 16)
      .frame(maxWidth: .infinity, alignment: .leading)
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
