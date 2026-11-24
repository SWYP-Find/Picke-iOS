//
//  ClassResultView.swift
//  Class
//
//  Created by Picke on 11/20/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

/// Android `ClassResultContent` 와 같은 구성: 헤더 → (두 탭이 모두 있을 때만) 탭 바 → 요약 또는 내 리포트.
@ViewAction(for: ClassResultFeature.self)
public struct ClassResultView: View {
  @Bindable public var store: StoreOf<ClassResultFeature>

  public init(store: StoreOf<ClassResultFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      ClassReportNavigationBar(
        title: store.loaded?.className ?? store.room.name,
        backAccessibilityIdentifier: "class-result-back",
        onBack: { send(.backTapped) }
      )
      .padding(.horizontal, 16)

      if store.isLoading {
        skeleton()
      } else if let loaded = store.loaded {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            header(loaded)
            Section {
              switch store.visibleTab {
              case .summary:
                summarySection(loaded)
              case .report:
                if let report = loaded.report {
                  reportSection(report, loaded: loaded)
                }
              }
            } header: {
              if store.isTabVisible {
                tabBar()
              }
            }
          }
        }
        .scrollIndicators(.hidden)
      } else {
        PickeLoadFailedSection()
          .frame(maxWidth: .infinity)
          .padding(16)
        Spacer(minLength: 0)
      }
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .onChange(of: store.toastMessage, initial: true) { _, message in
      guard let message else { return }
      ToastManager.shared.showError(message)
      send(.toastShown)
    }
  }
}

// MARK: - Header · Tab

private extension ClassResultView {
  @ViewBuilder
  func skeleton() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SkeletonView(.round(cornerRadius: 2)).frame(width: 120, height: 20)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 31)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 88)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 150, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 152)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 150, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 134)
      }
      .padding(16)
    }
    .accessibilityLabel("클래스 결과를 불러오는 중")
  }

  @ViewBuilder
  func header(_ loaded: ClassResultContent) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        if loaded.isInProgress {
          Text("진행 중")
            .pickeBadge(.filled, size: .tag)
        } else {
          Text("종료")
            .pretendardFont(.semiBold12)
            .foregroundStyle(.gray300)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .roundedBackground(.gray50)
        }
        if !loaded.tag.isEmpty {
          Text(loaded.tag)
            .pickeBadge(.filled, size: .tag)
        }
      }
      VStack(alignment: .leading, spacing: 8) {
        Text(loaded.battleTitle)
          .pretendardFont(family: .SemiBold, size: 24)
          .foregroundStyle(.gray800)
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(deadlineText(loaded.deadline) + "까지")
          .pretendardFont(family: .Regular, size: 13)
          .foregroundStyle(.gray300)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  func tabBar() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassResultTab.allCases, id: \.self) { tab in
        let isSelected = store.visibleTab == tab
        Button { send(.tabSelected(tab)) } label: {
          Text(tab.rawValue)
            .pretendardFont(family: .Medium, size: 13)
            .foregroundStyle(isSelected ? .primary500 : .gray300)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .overlay(alignment: .bottom) {
              Rectangle()
                .fill(isSelected ? .primary500 : .gray100)
                .frame(height: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("class-result-tab.\(tab.rawValue)")
      }
    }
    .background(Color.bgBeige)
  }

  func deadlineText(_ date: Date) -> String {
    date.formatted(.dottedDateTimeWithWeekday)
  }
}

// MARK: - 클래스 요약 탭

private extension ClassResultView {
  @ViewBuilder
  func summarySection(_ loaded: ClassResultContent) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      if let insight = loaded.insight {
        aiInsightCard(insight, deadline: loaded.deadline)
      }

      titledBlock("클래스 참여 현황", size: 14) {
        participationCard(loaded.stats)
      }

      titledBlock("입장 분포", size: 14) {
        ClassResultStanceCard(options: loaded.stats.options)
      }
      // Android: 주요 의견은 BEST·최다 논쟁 댓글이 모두 있을 때만 보인다(현재 서버 연동 전이라 항상 숨김).
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 24)
  }

  @ViewBuilder
  func aiInsightCard(_ insight: ClassResultInsightBoard, deadline: Date) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      aiLabel("AI 인사이트", size: 11, family: .Bold)
      Text(insightText(insight, deadline: deadline))
        .pretendardFont(family: .Regular, size: 12)
        .foregroundStyle(.primary500)
        .frame(maxWidth: .infinity, alignment: .leading)
      if store.isInsightRetryEnabled {
        Button { send(.insightRetryTapped) } label: {
          Text("다시 시도")
            .pretendardFont(family: .SemiBold, size: 12)
            .foregroundStyle(.primary500)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(Capsule().stroke(.primary500, lineWidth: 1))
        }
        .buttonStyle(.plain)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.surfacePrimarySubtle, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.primary100, lineWidth: 1))
  }

  func insightText(_ insight: ClassResultInsightBoard, deadline: Date) -> String {
    switch insight.state {
    case .beforeClose:
      "\(deadlineText(deadline)) 이후 AI 피드백이 제공돼요"
    case .pending, .generating:
      "생각을 정리하고 있어요"
    case .succeeded:
      insight.insightText ?? ""
    case .limited:
      "아직 요약할 의견이 충분하지 않아요"
    case .notEligible, .failed:
      "AI 요약을 준비하지 못했어요"
    }
  }

  @ViewBuilder
  func participationCard(_ stats: ClassResultStats) -> some View {
    VStack(spacing: 16) {
      participationRow(
        "배틀 참여율",
        caption: "참여한 멤버",
        count: stats.completedCount,
        memberCount: stats.activeMemberCount,
        tint: .primary500
      )
      participationRow(
        "댓글 작성율",
        caption: "댓글을 남긴 멤버",
        count: stats.commentWriterCount,
        memberCount: stats.activeMemberCount,
        tint: .secondary500
      )
    }
    .padding(16)
    .resultCard()
  }

  @ViewBuilder
  func participationRow(
    _ title: String,
    caption: String,
    count: Int,
    memberCount: Int,
    tint: Color
  ) -> some View {
    let ratio = memberCount > 0 ? min(max(Double(count) / Double(memberCount), 0), 1) : 0
    VStack(spacing: 4) {
      VStack(spacing: 6) {
        HStack {
          Text(title)
            .pretendardFont(family: .SemiBold, size: 12)
          Spacer()
          Text(memberCount > 0 ? "\(ClassResultFormat.rate(ratio * 100))%" : "아직 참여 없음")
            .pretendardFont(family: .SemiBold, size: 14)
        }
        .foregroundStyle(.gray800)
        HStack {
          Text(caption)
          Spacer()
          Text("\(count) / \(memberCount)명")
        }
        .pretendardFont(family: .Regular, size: 11)
        .foregroundStyle(.gray300)
      }
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(Color.bgSubtle)
          Capsule().fill(tint).frame(width: geometry.size.width * ratio)
        }
      }
      .frame(height: 6)
    }
  }
}

// MARK: - 내 리포트 탭

private extension ClassResultView {
  @ViewBuilder
  func reportSection(
    _ report: ClassResultMyReportBoard,
    loaded: ClassResultContent
  ) -> some View {
    VStack(alignment: .leading, spacing: 24) {
      titledBlock("내 투표 결과", size: 13) {
        myVoteCard(report, receivedLikeCount: loaded.receivedLikeCount)
      }
      titledBlock("AI 피드백", size: 13) {
        feedbackCard(report, deadline: loaded.deadline)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
    .padding(.bottom, 24)
  }

  @ViewBuilder
  func myVoteCard(_ report: ClassResultMyReportBoard, receivedLikeCount: Int?) -> some View {
    let pre = report.preOptionTitle ?? ""
    let post = report.postOptionTitle ?? ""
    VStack(spacing: 0) {
      HStack(spacing: 0) {
        voteColumn("사전 선택", stance: pre)
        if pre != post {
          Text("입장 변경")
            .pretendardFont(family: .SemiBold, size: 10)
            .foregroundStyle(.beige50)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.primary500, in: Capsule())
        }
        voteColumn("사후 선택", stance: post)
      }
      .padding(.vertical, 12)
      .background(Color.surfaceBeigeSubtle, in: RoundedRectangle(cornerRadius: 2))
      .padding([.horizontal, .top], 16)

      HStack(spacing: 0) {
        statColumn(report.perspectiveCount, label: "댓글")
        Rectangle().fill(.beige600).frame(width: 1)
        statColumn(report.commentCount, label: "대댓글")
        Rectangle().fill(.beige600).frame(width: 1)
        statColumn(receivedLikeCount, label: "받은 추천")
      }
      .fixedSize(horizontal: false, vertical: true)
      .padding(16)
    }
    .resultCard()
  }

  func voteColumn(_ label: String, stance: String) -> some View {
    VStack(spacing: 4) {
      Text(label)
        .pretendardFont(family: .Medium, size: 11)
        .foregroundStyle(.gray300)
      Text(stance)
        .pretendardFont(family: .SemiBold, size: 12)
        .foregroundStyle(.gray800)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
  }

  func statColumn(_ count: Int?, label: String) -> some View {
    VStack(spacing: 0) {
      Text(count.map(String.init) ?? "-")
        .pretendardFont(family: .Bold, size: 16)
        .foregroundStyle(.gray800)
      Text(label)
        .pretendardFont(family: .Medium, size: 10)
        .foregroundStyle(.gray300)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func feedbackCard(_ report: ClassResultMyReportBoard, deadline: Date) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      if let basis = report.feedback?.judgmentBasis,
         !basis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      {
        VStack(alignment: .leading, spacing: 6) {
          aiLabel("내 판단의 기준", size: 12, family: .SemiBold)
          Text(basis)
            .pretendardFont(family: .Regular, size: 12)
            .foregroundStyle(.primary500)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfacePrimarySubtle)
      }

      VStack(alignment: .leading, spacing: 16) {
        if let notice = feedbackNotice(report, deadline: deadline) {
          Text(notice)
            .pretendardFont(family: .Regular, size: 13)
            .foregroundStyle(.gray300)
          divider()
        }

        ForEach(feedbackItems(report), id: \.title) { item in
          VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
              .pretendardFont(family: .SemiBold, size: 12)
              .foregroundStyle(.primary500)
            Text(item.content)
              .pretendardFont(family: .Regular, size: 13)
              .foregroundStyle(.textSubtle)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          divider()
        }

        Button { send(.myOpinionTapped) } label: {
          HStack {
            Text("내가 남긴 의견 \(report.perspectiveCount + report.commentCount)개 보기")
              .pretendardFont(family: .Bold, size: 12)
            Spacer()
            Image(systemName: "chevron.right")
              .font(.system(size: 10, weight: .semibold))
          }
          .foregroundStyle(.primary500)
          .padding(.vertical, 6)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
      .padding(16)
    }
    .clipShape(RoundedRectangle(cornerRadius: 2))
    .resultCard()
  }

  /// Android `ClassResultFeedbackBoard.toFeedbackItems` — 고정 제목 3개.
  func feedbackItems(_ report: ClassResultMyReportBoard) -> [(title: String, content: String)] {
    guard let feedback = report.feedback else { return [] }
    var items: [(title: String, content: String)] = []
    if let strength = feedback.strength {
      items.append(("이번에 잘한 점", strength))
    }
    if let nextFocus = feedback.nextFocus {
      items.append(("한 가지 더 살펴볼 점", nextFocus))
    }
    items.append(("다음 생각 한 걸음", feedback.nextQuestion))
    return items
  }

  func feedbackNotice(_ report: ClassResultMyReportBoard, deadline: Date) -> String? {
    switch report.state {
    case .beforeClose:
      "\(deadlineText(deadline)) 이후 AI 피드백이 제공돼요"
    case .notEligible:
      "참여를 완료하면 AI 피드백을 받을 수 있어요"
    case .pending, .generating:
      "생각을 정리하고 있어요"
    case .succeeded:
      report.feedback?.coverage == "partial" ? "이번 피드백은 일부 발언을 기준으로 작성했어요" : nil
    case .limited:
      "판단의 이유를 살펴볼 글이 아직 충분하지 않아요"
    case .failed:
      "AI 요약을 준비하지 못했어요"
    }
  }
}

// MARK: - 공통

private extension ClassResultView {
  func titledBlock(
    _ title: String,
    size: CGFloat,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .pretendardFont(family: .SemiBold, size: size)
        .foregroundStyle(.gray800)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  func aiLabel(_ title: String, size: CGFloat, family: PretendardFontFamily) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "sparkle")
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.beige50)
        .frame(width: 20, height: 20)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 6))
      Text(title)
        .pretendardFont(family: family, size: size)
        .foregroundStyle(.primary500)
    }
  }

  func divider() -> some View {
    Rectangle().fill(.beige600).frame(height: 1)
  }
}

private extension View {
  func resultCard() -> some View {
    background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}

/// Android `formatRate`: 소수 첫째 자리, `.0` 은 생략.
enum ClassResultFormat {
  static func rate(_ value: Double) -> String {
    let text = String(format: "%.1f", value)
    return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
  }

  /// Android `stanceRates`: 0.1% 단위로 반올림하고 마지막 항목이 나머지를 가져가 합이 100% 가 되게 한다.
  static func stanceRates(_ counts: [Int]) -> [Double]? {
    let total = counts.reduce(0, +)
    guard total > 0 else { return nil }
    let leading = counts.dropLast().map { Int((Double($0) * 1000 / Double(total)).rounded()) }
    let last = 1000 - leading.reduce(0, +)
    return (leading + [last]).map { Double($0) / 10 }
  }
}

/// Android `ClassResultStanceCard`: 도넛 차트 + 옵션별 사후 투표 수·비율.
struct ClassResultStanceCard: View {
  let options: [ClassResultOption]

  private let colors: [Color] = [.primary500, .secondary500]

  var body: some View {
    let counts = options.map(\.postVoteCount)
    let total = counts.reduce(0, +)
    let rates = ClassResultFormat.stanceRates(counts)
    HStack(spacing: 24) {
      ZStack {
        chart(counts: counts, total: total)
        VStack(spacing: 0) {
          Text("\(total)명")
            .pretendardFont(family: .Bold, size: 16)
            .foregroundStyle(.gray800)
          Text("총 참여")
            .pretendardFont(family: .Medium, size: 10)
            .foregroundStyle(.gray300)
        }
      }
      .frame(width: 100, height: 100)

      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
          HStack(spacing: 8) {
            Circle()
              .fill(colors[index % colors.count])
              .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 0) {
              Text(option.title)
                .pretendardFont(family: .SemiBold, size: 12)
                .foregroundStyle(.gray800)
                .lineLimit(1)
              Text("\(option.postVoteCount)명")
                .pretendardFont(family: .Medium, size: 11)
                .foregroundStyle(.gray300)
            }
            Spacer(minLength: 8)
            Text(rates.map { "\(ClassResultFormat.rate($0[index]))%" } ?? "아직 참여 없음")
              .pretendardFont(family: .Bold, size: 12)
              .foregroundStyle(.gray800)
          }
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  private func chart(counts: [Int], total: Int) -> some View {
    let lineWidth: CGFloat = 12
    ZStack {
      if total == 0 {
        Circle().stroke(Color.bgSubtle, lineWidth: lineWidth)
      } else {
        ForEach(Array(segments(counts: counts, total: total).enumerated()), id: \.offset) { index, segment in
          Circle()
            .trim(from: segment.start, to: segment.end)
            .stroke(colors[index % colors.count], style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .rotationEffect(.degrees(-90))
        }
      }
    }
    .padding(lineWidth / 2)
  }

  private func segments(counts: [Int], total: Int) -> [(start: CGFloat, end: CGFloat)] {
    var start: CGFloat = 0
    return counts.map { count in
      let end = start + CGFloat(count) / CGFloat(total)
      defer { start = end }
      return (start, end)
    }
  }
}
