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

      ScrollView {
        VStack(spacing: 16) {
          reportTitle()
          reportTabs()
          reportContent()
            .padding(.horizontal, 16)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.visible, for: .tabBar)
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
  func reportContent() -> some View {
    VStack(spacing: 16) {
      switch store.selectedTab {
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
      voteChange()
      participationCounts()
    }
    reportCard {
      cardHeading("AI 리포트", destination: .feedback)
      Text("다른 해결방법까지 생각을 확장했어요")
        .pretendardFont(family: .SemiBold, size: 18)
        .foregroundStyle(.gray800)
      Text("“교육과 보호도 함께 필요하다”는 대댓글에서 처벌 외의 대안을 제시했어요")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    reportCard {
      cardHeading("선생님 피드백", destination: .feedback)
      Text("“왜 생각이 달라졌는지 자신의 말로 설명한 점이 좋았어요”")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func participationContent() -> some View {
    reportCard {
      cardHeading("내 투표 결과")
      voteChange()
      participationCounts()
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("내 댓글")
      HStack {
        Text("낮춰야 한다").pickeBadge(.filled, size: .tag)
        Spacer()
        Text("26.09.23. 14:02")
          .pretendardFont(family: .SemiBold, size: 10)
          .foregroundStyle(.gray300)
      }
      Text("청소년 범죄가 날로 잔혹해지는 만큼 처벌 연령을 낮춰야 한다고 생각해요. 피해자 보호를 위해서라도 책임을 물어야 해요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      HStack(spacing: 12) {
        Label("1,340", systemImage: "heart")
        Label("23", systemImage: "bubble")
      }
      .pretendardFont(.regular13)
      .foregroundStyle(.gray300)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("내 대댓글")
      VStack(alignment: .leading, spacing: 4) {
        Text("김민지 · 교정이 우선이다")
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.gray500)
        Text("“피해자 보호를 위한 기준도 함께 필요하지 않을까요?”")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      Text("↳ 내 대댓글")
        .pretendardFont(family: .SemiBold, size: 12)
        .foregroundStyle(.primary500)
      Text("처벌만으로는 해결되지 않아요. 교육과 보호도 함께 필요하다고 생각해요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      HStack {
        Text("26.09.23. 14:02")
        Spacer()
        Label("12", systemImage: "heart")
      }
      .pretendardFont(family: .SemiBold, size: 10)
      .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func classResultContent() -> some View {
    reportCard {
      cardHeading("우리 클래스 참여 현황")
      HStack {
        Text("참여한 학생")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
        Spacer()
        Text("28 / 32")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
      }
      voteBar("사전 투표 결과", primary: "낮춰야 한다", secondary: "교정이 우선이다", fraction: 0.67, color: .secondary500)
      voteBar("사후 투표 결과", primary: "낮춰야 한다", secondary: "교정이 우선이다", fraction: 0.49, color: .primary500)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("클래스 결과 요약")
      Text("입장을 바꾼 학생은 6명이에요.\n연령하향 → 교정우선 5명, 교정 우선 → 연령 하향 1명이에요.\n교정 우선 선택은 10명에서 14명으로 늘었어요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("BEST 댓글")
      Text("김민지 · 교정이 우선이다")
        .pretendardFont(family: .SemiBold, size: 12)
        .foregroundStyle(.gray500)
      Text("“피해자 보호를 위한 기준도 함께 필요하지 않을까요?”")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      Text("좋아요 1,340  ·  대댓글 23")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
  }

  @ViewBuilder
  func feedbackContent() -> some View {
    reportCard {
      cardHeading("AI 피드백")
      feedbackRow(
        "내 생각의 변화를 설명했어요",
        description: "“처벌만으로는 해결되지 않는 점”을 언급하며, 처음과 입장이 달리진 이유를 드러냈어요.",
        icon: "arrow.left.arrow.right"
      )
      Divider().overlay(.beige500)
      feedbackRow("다른 해결방법을 제안했어요", description: "반대의견에 그치지 않고 “교육과 보호”라는 대안을 덧붙였어요.", icon: "lightbulb")
      Divider().overlay(.beige500)
      feedbackRow("근거를 한 단계 더 구체적으로", description: "교육과 보호가 재범을 줄이는 데 어떤 도움이 되는지, 사례나 자료 하나를 연결하면 주장이 더 설득력 있어져요.", icon: "sparkles")
      Divider().overlay(.beige500)
      Text("분석에 사용한 내 대댓글 보기")
        .pretendardFont(family: .Bold, size: 12)
        .foregroundStyle(.primary500)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("다음 생각 해보기")
      Text("처벌과 교화를 함께 한다면,\n무엇을 기준으로 균형을 잡을까요?")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      Text("내 의견과 반대되는 입장도 함께 떠올려 보세요.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray300)
    }
    reportCard(padding: 16, spacing: 8) {
      cardHeading("선생님 피드백")
      Text("처음과 나중의 생각이 어떻게 달라졌는지 스스로 정리한 점이 좋았어요. 단순히 입장을 바꾸는 데서 끝나지 않고, 왜 바뀌었는지 설명하려는 태도가 인상적이었습니다.")
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
      HStack {
        Text("김민지 선생님")
        Spacer()
        Text("26.09.23. 14:02")
      }
      .pretendardFont(family: .SemiBold, size: 10)
      .foregroundStyle(.gray300)
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
  func voteChange() -> some View {
    HStack(spacing: 0) {
      voteChoice("사전 선택", value: "낮춰야 한다")
      Text("입장 변경")
        .pretendardFont(family: .SemiBold, size: 10)
        .foregroundStyle(.beige50)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.primary500, in: Capsule())
      voteChoice("사후 선택", value: "교정이 우선이다")
    }
    .frame(height: 60)
    .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func voteChoice(_ label: String, value: String) -> some View {
    VStack(spacing: 4) {
      Text(label)
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.gray300)
      Text(value)
        .pretendardFont(family: .SemiBold, size: 12)
        .foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func participationCounts() -> some View {
    HStack(spacing: 0) {
      count("1", label: "댓글")
      Rectangle().fill(.beige600).frame(width: 1, height: 47)
      count("12", label: "대댓글")
      Rectangle().fill(.beige600).frame(width: 1, height: 47)
      count("8", label: "받은 좋아요")
    }
    .frame(height: 55)
  }

  @ViewBuilder
  func count(_ value: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(value).pretendardFont(.semiBold15).foregroundStyle(.gray800)
      Text(label).pretendardFont(.regular13).foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func voteBar(_ title: String, primary: String, secondary: String, fraction: CGFloat, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).pretendardFont(.regular13).foregroundStyle(.gray500)
      GeometryReader { proxy in
        HStack(spacing: 12) {
          Text(primary)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray800)
            .frame(width: proxy.size.width * fraction, height: 34)
            .background(color, in: RoundedRectangle(cornerRadius: 2))
          Text(secondary)
            .pretendardFont(.regular13)
            .foregroundStyle(.gray500)
        }
      }
      .frame(height: 34)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
    }
  }

  @ViewBuilder
  func feedbackRow(_ title: String, description: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 6) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundStyle(.primary500)
        .frame(width: 24, height: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
        Text(description).pretendardFont(.regular13).foregroundStyle(.gray500)
      }
    }
  }
}
