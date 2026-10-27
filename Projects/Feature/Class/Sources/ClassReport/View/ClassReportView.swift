//
//  ClassReportView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import PickeCoreUtility
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassReportFeature.self)
public struct ClassReportView: View {
  @Bindable public var store: StoreOf<ClassReportFeature>

  public init(store: StoreOf<ClassReportFeature>) {
    self.store = store
  }

  private func reportText(_ key: ClassReport.Key) -> String {
    store.report?[key] ?? ""
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar

      reportTitle()
        .padding(.vertical, 12)
      if store.sourceViewState == .failed {
        PickeRetryErrorView(message: store.sourceErrorMessage) { send(.retryTapped) }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.sourceViewState == .loading {
        sourceSkeleton()
      } else if let classResult = store.classResult {
        if store.room.role == .member {
          memberResultPages(classResult)
        } else {
          serverResultPages(classResult)
        }
      } else {
        reportPages()
      }
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
  }
}

private extension ClassReportView {
  var insightBackground: Color { Color(hex: "FCF5F3") }

  var navigationBar: some View {
    ClassReportNavigationBar(
      title: store.room.name,
      onBack: { send(.backTapped) }
    )
  }

  @ViewBuilder
  func sourceSkeleton() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SkeletonView(.round(cornerRadius: 2)).frame(width: 120, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 136)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 120, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 350)
      }
      .padding(16)
    }
    .accessibilityLabel("리포트를 불러오는 중")
  }

  @ViewBuilder
  func memberResultPages(_ result: ClassResult) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 12) {
          sectionHeading("내 투표 결과")
          reportCard(padding: 16, spacing: 16) {
            memberVoteSummary()
          }
        }

        if result.myReportState != nil {
          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("AI 피드백")
            reportCard(padding: 0, horizontalPadding: 0, spacing: 0) {
              if case let .ready(feedback) = store.feedbackViewState {
                aiFeedbackSummary(feedback)
              } else {
                VStack(alignment: .leading, spacing: 16) {
                  feedbackStatus()
                  Rectangle().fill(.beige700).frame(height: 1)
                  myOpinionsSection
                }
                .padding(16)
              }
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 28)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  func memberVoteSummary() -> some View {
    if let preVoteTitle = store.personalPreVoteTitle {
      HStack(spacing: 0) {
        voteChoice("사전 선택", value: preVoteTitle)
        if let postVoteTitle = store.personalPostVoteTitle {
          Text(store.personalOpinionChanged ? "입장 변경" : "입장 유지")
            .pretendardFont(.labelXSmall)
            .foregroundStyle(.beige50)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.primary500, in: Capsule())
          voteChoice("사후 선택", value: postVoteTitle)
        } else {
          voteChoice("사후 선택", value: "투표 전")
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      HStack(spacing: 0) {
        activityCount(store.feedback.map { String($0.perspectiveCount) } ?? "—", label: "작성한 의견")
        Rectangle().fill(.beige600).frame(width: 1, height: 38)
        activityCount(store.feedback.map { String($0.commentCount) } ?? "—", label: "작성한 댓글")
      }
    } else if store.voteHistoryRequestID != nil {
      SkeletonView(.round(cornerRadius: 2)).frame(height: 48)
        .accessibilityLabel("내 투표 결과를 불러오는 중")
    } else {
      unavailableReport(
        title: "내 투표 결과를 불러올 수 없어요",
        message: "잠시 후 다시 확인해 주세요."
      )
    }
  }

  @ViewBuilder
  func serverResultPages(_ result: ClassResult) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        if let insight = store.insight {
          insightCard(insight)
        } else if result.insightState != nil {
          insightUnavailable()
        }

        VStack(alignment: .leading, spacing: 12) {
          sectionHeading("클래스 참여 현황")
          reportCard {
            participationBar(
              title: "배틀 참여율",
              rate: result.stats.participationRate,
              detail: "\(result.stats.completedCount) / \(result.stats.activeMemberCount)명",
              color: .primary500
            )
            participationBar(
              title: "댓글 작성률",
              rate: result.stats.commentRate,
              detail: "\(result.stats.commentWriterCount) / \(result.stats.activeMemberCount)명",
              color: .secondary500
            )
          }
        }

        VStack(alignment: .leading, spacing: 12) {
          sectionHeading("입장 분포")
          reportCard {
            stanceDistribution(result.stats.options)
          }
        }

        if let insight = store.insight, !insight.highlights.isEmpty {
          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("주요 의견")
            reportCard(padding: 0, horizontalPadding: 0, spacing: 0) {
              ForEach(insight.highlights.indices, id: \.self) { index in
                highlightRow(insight.highlights[index], index: index)
                if index < insight.highlights.count - 1 {
                  Rectangle().fill(.beige600).frame(height: 1)
                }
              }
            }
          }
        }

        if result.myReportState != nil {
          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("내 AI 피드백")
            reportCard {
              if case let .ready(feedback) = store.feedbackViewState {
                Text(feedback.summaryTitle)
                  .pretendardFont(.semiBold15)
                  .foregroundStyle(.gray800)
                Text(feedback.summaryDetail)
                  .pretendardFont(.regular13)
                  .foregroundStyle(.gray700)
                ForEach(feedback.points.indices, id: \.self) { index in
                  feedbackPoint(feedback.points[index].title, detail: feedback.points[index].detail)
                }
                feedbackEvidence(feedback)
              } else if result.myReportState == "BEFORE_CLOSE" {
                unavailableReport(
                  title: "마감 후 AI 피드백을 볼 수 있어요",
                  message: store.serverFeedbackAvailabilityMessage
                )
              } else {
                feedbackStatus()
              }
            }
            reportCard { myOpinionsSection }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 16)
      .padding(.bottom, 28)
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  func insightCard(_ insight: ClassAIInsight) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      ClassAIInsightHeading(
        title: "AI 인사이트",
        titleFont: .semiBold12,
        titleLineHeight: 17,
        iconSize: 20,
        spacing: 6
      )
      Text(insight.text)
        .pretendardFont(.regular13)
        .foregroundStyle(.primary500)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(insightBackground)
    .overlay(Rectangle().stroke(.primary100, lineWidth: 1))
  }

  @ViewBuilder
  func insightUnavailable() -> some View {
    VStack(alignment: .leading, spacing: 8) {
      ClassAIInsightHeading(
        title: "AI 인사이트",
        titleFont: .semiBold12,
        titleLineHeight: 17,
        iconSize: 20,
        spacing: 6
      )
      Text(store.insightStatusMessage)
        .pretendardFont(.regular13)
        .foregroundStyle(.primary500)
      if store.canRetryInsight {
        Button("다시 시도") { send(.insightRetryTapped) }
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
          .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(insightBackground)
    .overlay(Rectangle().stroke(.primary100, lineWidth: 1))
  }

  @ViewBuilder
  func participationBar(
    title: String,
    rate: Double,
    detail: String,
    color: Color
  ) -> some View {
    let progress = min(max(rate / 100, 0), 1)
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text(title)
          .pretendardFont(.semiBold12)
        Spacer()
        Text(rate.formatted(.number.precision(.fractionLength(0...1))) + "%")
          .pretendardFont(.semiBold12)
      }
      .foregroundStyle(.gray800)
      Text(detail)
        .pretendardFont(.medium10)
        .foregroundStyle(.gray300)
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(.beige500)
          Capsule().fill(color).frame(width: geometry.size.width * progress)
        }
      }
      .frame(height: 5)
    }
    .padding(.vertical, 2)
  }

  @ViewBuilder
  func stanceDistribution(_ options: [ClassResultOption]) -> some View {
    let firstRatio = min(max((options.first?.postVoteRatio ?? 0) / 100, 0), 1)
    HStack(spacing: 24) {
      ZStack {
        Circle().stroke(.secondary500, lineWidth: 12)
        Circle()
          .trim(from: 0, to: firstRatio)
          .stroke(.primary500, style: StrokeStyle(lineWidth: 12, lineCap: .butt))
          .rotationEffect(.degrees(-90))
        VStack(spacing: 1) {
          Text("\(options.reduce(0) { $0 + $1.postVoteCount })명")
            .pretendardFont(.semiBold15)
            .foregroundStyle(.gray800)
          Text("총 참여")
            .pretendardFont(.medium10)
            .foregroundStyle(.gray300)
        }
      }
      .frame(width: 100, height: 100)
      VStack(alignment: .leading, spacing: 10) {
        ForEach(Array(options.prefix(2).enumerated()), id: \.element.id) { index, option in
          HStack(spacing: 6) {
            Circle()
              .fill(index == 0 ? Color.primary500 : Color.secondary500)
              .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 2) {
              Text(option.title)
                .pretendardFont(.semiBold11)
                .foregroundStyle(.gray800)
                .lineLimit(1)
              Text("\(option.postVoteCount)명")
                .pretendardFont(.medium10)
                .foregroundStyle(.gray300)
            }
            Spacer(minLength: 2)
            Text(option.postVoteRatio.formatted(.number.precision(.fractionLength(0...1))) + "%")
              .pretendardFont(.semiBold11)
              .foregroundStyle(.gray800)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func highlightRow(_ evidence: ClassAIFeedbackEvidence, index: Int) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("주요 의견 \(index + 1)")
        .pretendardFont(.semiBold11)
        .foregroundStyle(.primary500)
      Text(evidence.quote ?? evidence.content)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
  }

  @ViewBuilder
  func feedbackStatus() -> some View {
    switch store.feedbackViewState {
    case .loading:
      VStack(alignment: .leading, spacing: 12) {
        SkeletonView(.round(cornerRadius: 2)).frame(width: 144, height: 20)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 14)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 220, height: 14)
      }
      .accessibilityLabel("AI 피드백을 불러오는 중")
    case .retryableFailure:
      PickeRetryErrorView(message: "AI 피드백을 불러오지 못했어요") { send(.feedbackRetryTapped) }
    case .pending:
      VStack(alignment: .leading, spacing: 12) {
        unavailableReport(title: store.feedbackStatusTitle, message: store.feedbackStatusMessage)
        Button("다시 확인") { send(.feedbackRetryTapped) }
          .pretendardFont(.semiBold13)
          .foregroundStyle(.primary500)
          .buttonStyle(.plain)
      }
    case .failure:
      unavailableReport(title: store.feedbackStatusTitle, message: store.feedbackStatusMessage)
    case .unavailable:
      unavailableReport(title: store.feedbackStatusTitle, message: store.feedbackStatusMessage)
    case .ready:
      EmptyView()
    }
  }

  @ViewBuilder
  func nextThought() -> some View {
    if case let .ready(feedback) = store.feedbackViewState {
      VStack(alignment: .leading, spacing: 12) {
        Text(feedback.nextQuestion)
          .pretendardFont(family: .SemiBold, size: 18)
          .foregroundStyle(.gray800)
        Text(feedback.nextHint)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
      }
    }
  }

  @ViewBuilder
  func reportTitle() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 6) {
        statusBadge()
        if !store.room.battle.categoryDisplayTitle.isEmpty {
          Text("#\(store.room.battle.categoryDisplayTitle)")
            .frame(minHeight: 17)
            .pickeBadge(.filled, size: .tag)
        }
      }
      VStack(alignment: .leading, spacing: 8) {
        Text(store.room.battle.title)
          .pretendardFont(.semiBold24)
          .foregroundStyle(.gray800)
          .lineLimit(2)
          .frame(minHeight: 31)
        let deadline = store.classResult?.closeAt ?? store.room.deadline
        Text(deadline == .distantFuture
          ? "마감일 없음"
          : deadline.formatted(.dottedDateTimeWithWeekday) + "까지")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
          .frame(minHeight: 18)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
  }

  @ViewBuilder
  func statusBadge() -> some View {
    switch store.classResult?.closed == true ? ClassStatus.closed : store.room.status {
    case .open:
      Text("진행 중")
        .frame(minHeight: 17)
        .pickeBadge(.filled, size: .tag)
    case .closed:
      Text("마감")
        .pretendardFont(.semiBold12)
        .foregroundStyle(.gray300)
        .padding(.horizontal, 4)
        .frame(height: 20)
        .roundedBackground(.gray50, radius: 2)
    }
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
    if store.showsSummaryLayout {
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
        reportCard(
          padding: 16,
          spacing: 16,
          minHeight: store.report != nil ? 146 : 0
        ) {
          voteAndActivitySummary()
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        sectionHeading("AI 피드백")
        reportCard(padding: 0, horizontalPadding: 0, spacing: 0) {
          VStack(alignment: .leading, spacing: 0) {
            switch store.feedbackViewState {
            case let .ready(feedback):
              aiFeedbackSummary(feedback)
            default:
              feedbackStatus()
                .padding(16)
              if store.report != nil {
                VStack(alignment: .leading, spacing: 16) {
                  Rectangle().fill(.beige700).frame(height: 1)
                  myOpinionsSection
                }
                .padding(16)
              }
            }
          }
          .padding(1)
        }
      }

      if !store.showsSummaryLayout {
        if case .ready = store.feedbackViewState {
          VStack(alignment: .leading, spacing: 12) {
            sectionHeading("다음 생각 해보기")
            nextThought()
              .padding(16)
              .frame(maxWidth: .infinity, alignment: .leading)
              .pickeCard(.beige100, border: .beige600, radius: 2)
          }
        }

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
    reportCard(minHeight: store.report != nil ? 204 : 0) {
      cardHeading("내 투표 결과")
      voteAndActivitySummary()
    }
    reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 177 : 0) {
      cardHeading("내 댓글")
      if store.report != nil {
        HStack {
          Text(reportText(.commentStance)).pickeBadge(.filled, size: .tag)
          Spacer()
          Text(reportText(.commentDate)).pretendardFont(family: .Regular, size: 12).foregroundStyle(.gray300)
        }
        Text(reportText(.commentBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        reactions(likes: reportText(.commentLikes), replies: reportText(.commentReplies))
      } else {
        unavailableReport(
          title: "댓글 데이터를 불러올 수 없어요",
          message: "댓글 데이터가 연결되면 이곳에서 확인할 수 있어요."
        )
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 225 : 0) {
      cardHeading("내 대댓글")
      if store.report != nil {
        Text(reportText(.replyAuthor))
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
        Text(reportText(.replyParent))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        Rectangle().fill(.beige600).frame(height: 1)
        Text("내 대댓글").pretendardFont(.semiBold13).foregroundStyle(.gray800)
        Text(reportText(.replyBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        HStack {
          Text(reportText(.replyDate))
          Spacer()
          Image(systemName: "heart")
          Text(reportText(.replyLikes))
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
    reportCard(minHeight: store.report != nil ? 243 : 0) {
      cardHeading("우리 클래스 참여 현황")
      HStack {
        Text(store.report != nil ? reportText(.participantTitle) : "클래스 멤버")
          .pretendardFont(.regular13)
          .foregroundStyle(.gray300)
        Spacer()
        Text(store.report != nil ? reportText(.participantCount) : "\(store.room.memberCount)명")
          .pretendardFont(.semiBold15)
          .foregroundStyle(.gray800)
      }
      if store.report != nil {
        voteDistribution(title: "사전 투표 결과", leading: store.report?.initialVoteLeading ?? 0)
        voteDistribution(title: "사후 투표 결과", leading: store.report?.finalVoteLeading ?? 0)
      } else {
        unavailableReport(
          title: "투표 분포를 집계할 수 없어요",
          message: "현재 클래스 데이터에는 투표 집계가 포함되어 있지 않아요."
        )
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 120 : 0) {
      cardHeading("클래스 결과 요약")
      if store.report != nil {
        Text(reportText(.classSummary))
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
    reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 142 : 0) {
      cardHeading("BEST 댓글")
      if store.report != nil {
        Text(reportText(.bestAuthor))
          .pretendardFont(.semiBold13)
          .foregroundStyle(.gray800)
        Text(reportText(.bestBody))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        reactions(likes: reportText(.bestLikes), replies: reportText(.bestReplies))
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
    reportCard(minHeight: store.report != nil ? 361 : 0) {
      cardHeading("AI 피드백")
      if case let .ready(feedback) = store.feedbackViewState {
        ForEach(feedback.points.indices, id: \.self) { index in
          feedbackPoint(feedback.points[index].title, detail: feedback.points[index].detail)
        }
        feedbackEvidence(feedback)
      } else {
        feedbackStatus()
      }
    }
    if case .ready = store.feedbackViewState {
      reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 138 : 0) {
        cardHeading("다음 생각 해보기")
        nextThought()
      }
    }
    reportCard(padding: 16, spacing: 8, minHeight: store.report != nil ? 142 : 0) {
      cardHeading("선생님 피드백")
      if store.report != nil {
        Text(reportText(.teacherFeedback))
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
        HStack {
          Text(reportText(.teacherName))
          Spacer()
          Text(reportText(.teacherDate))
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
      .pretendardFont(.semiBold13)
      .foregroundStyle(.gray800)
      .frame(minHeight: 18)
      .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func aiFeedbackSummary(_ feedback: ClassAIPersonalFeedback) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 6) {
        ClassAIInsightHeading(
          title: "내 판단의 기준",
          titleFont: .semiBold12,
          titleLineHeight: 17,
          iconSize: 20,
          spacing: 6
        )
        Text(feedback.summaryDetail)
          .pretendardFont(.bodySmall)
          .lineSpacing(feedbackSummaryLinePadding)
          .padding(.vertical, feedbackSummaryLinePadding / 2)
      }
      .foregroundStyle(.primary500)
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(insightBackground)

      VStack(alignment: .leading, spacing: 16) {
        ForEach(feedback.points.indices, id: \.self) { index in
          insightPoint(feedback.points[index].title, detail: feedback.points[index].detail)
          if index < feedback.points.count - 1 {
            Rectangle().fill(.beige700).frame(height: 1)
          }
        }
        feedbackEvidence(feedback)
        if store.report != nil || store.classResult?.myReportState != nil {
          Rectangle().fill(.beige700).frame(height: 1)
          myOpinionsSection
        }
      }
      .padding(16)
    }
  }

  @ViewBuilder
  func feedbackEvidence(_ feedback: ClassAIPersonalFeedback) -> some View {
    if let coverage = feedback.coverageDescription {
      Text(coverage)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
    }
    ForEach(feedback.evidence.indices, id: \.self) { index in
      Text(feedback.evidence[index].quote ?? feedback.evidence[index].content)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
    }
  }

  var myOpinionsSection: some View {
    Button { send(.myOpinionsTapped) } label: {
      HStack {
        Text(store.myOpinionsButtonTitle)
          .pretendardFont(family: .Bold, size: 12)
          .frame(minHeight: 17)
        Spacer()
        Image(systemName: "chevron.right")
          .pretendardFont(.semiBold12)
          .frame(width: 12, height: 12)
      }
      .foregroundStyle(.primary500)
      .padding(.vertical, 6)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("class-report-my-opinions")
  }

  var feedbackSummaryLinePadding: CGFloat {
    max(0, 12 * 1.4 - UIFont.pretendardFontFamily(family: .Regular, size: 12).lineHeight)
  }

  var feedbackDetailLinePadding: CGFloat {
    max(0, 13 * 1.4 - UIFont.pretendardFontFamily(family: .Regular, size: 13).lineHeight)
  }

  @ViewBuilder
  func insightPoint(
    _ label: String,
    detail: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .pretendardFont(.semiBold12)
        .foregroundStyle(.primary500)
        .frame(minHeight: 17)
      Text(detail)
        .pretendardFont(.regular13)
        .foregroundStyle(.gray700)
        .lineSpacing(feedbackDetailLinePadding)
        .padding(.vertical, feedbackDetailLinePadding / 2)
    }
  }

  @ViewBuilder
  func voteAndActivitySummary() -> some View {
    if store.report != nil {
      HStack(spacing: 0) {
        voteChoice("사전 선택", value: reportText(.initialChoice))
        Text("입장 변경")
          .pretendardFont(.labelXSmall)
          .foregroundStyle(.beige50)
          .frame(minHeight: 14)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.primary500, in: Capsule())
        voteChoice("사후 선택", value: reportText(.finalChoice))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(.beige300, in: RoundedRectangle(cornerRadius: 2))
      HStack(spacing: 0) {
        activityCount(reportText(.commentCount), label: "댓글")
        Rectangle().fill(.beige600).frame(width: 1, height: 38)
        activityCount(reportText(.replyCount), label: "대댓글")
        Rectangle().fill(.beige600).frame(width: 1, height: 38)
        activityCount(reportText(.receivedLikeCount), label: "받은 추천")
      }
    } else {
      unavailableReport(
        title: "내 투표와 참여 기록을 불러올 수 없어요",
        message: "리포트 데이터가 연결되면 이곳에서 확인할 수 있어요."
      )
    }
  }

  @ViewBuilder
  func voteChoice(
    _ title: String,
    value: String
  ) -> some View {
    VStack(spacing: 4) {
      Text(title).pretendardFont(.medium11).foregroundStyle(.gray300).frame(minHeight: 15)
      Text(value).pretendardFont(.semiBold12).foregroundStyle(.gray800).frame(minHeight: 17)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func activityCount(
    _ count: String,
    label: String
  ) -> some View {
    VStack(spacing: 0) {
      Text(count).pretendardFont(.labelLarge).foregroundStyle(.gray800).frame(minHeight: 24)
      Text(label).pretendardFont(.medium10).foregroundStyle(.gray300).frame(minHeight: 14)
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

  func voteDistribution(title: String, leading: Double) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).pretendardFont(.regular13).foregroundStyle(.gray700)
      GeometryReader { geometry in
        HStack(spacing: 0) {
          Rectangle().fill(Color.primary500).frame(width: geometry.size.width * CGFloat(leading))
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
    horizontalPadding: CGFloat = 16,
    spacing: CGFloat = 12,
    minHeight: CGFloat = 0,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: spacing, content: content)
      .padding(.vertical, padding)
      .padding(.horizontal, horizontalPadding)
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
      requiresComment: room.requiresComment,
      memberCapacity: room.memberCapacity
    )
    var state = ClassReportFeature.State(room: completedRoom)
    state.selectedTab = tab
    let fixture = MockClassReport.figma
    let report = ClassReport(
      texts: fixture.texts,
      myOpinions: fixture.myOpinions,
      initialVoteLeading: fixture.initialVoteLeading,
      finalVoteLeading: fixture.finalVoteLeading,
      layout: tab == .summary ? .summary : .tabbed,
      opinionEntries: fixture.opinionEntries
    )
    let repository = MockClassRepository(
      rooms: [completedRoom],
      availableRooms: [],
      reports: [completedRoom.id: report]
    )
    return Store(initialState: state) {
      ClassReportFeature()
        .dependency(\.classResultUseCase, repository)
    }
  }

  #Preview("리포트 · 요약") {
    ClassReportView(store: figmaReportStore(tab: .summary))
  }

  #Preview("리포트 · 내 참여") {
    ClassReportView(store: figmaReportStore(tab: .participation))
  }

  #Preview("리포트 · 클래스 결과") {
    ClassReportView(store: figmaReportStore(tab: .classResult))
  }

  #Preview("리포트 · 피드백") {
    ClassReportView(store: figmaReportStore(tab: .feedback))
  }
#endif
