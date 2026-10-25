//
//  ClassOwnerDashboardView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeDesignKit
import PickeSharedUI
import SwiftUI
import UIKit

@ViewAction(for: ClassOwnerDashboardFeature.self)
public struct ClassOwnerDashboardView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Bindable public var store: StoreOf<ClassOwnerDashboardFeature>
  @State private var chartProgress: CGFloat = 0

  public init(store: StoreOf<ClassOwnerDashboardFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      navigationBar
      titleHeader()
      dashboardTabs()
      if store.sourceViewState == .loading {
        sourceSkeleton()
      } else if store.sourceViewState == .failed {
        PickeRetryErrorView(message: "클래스 현황을 불러오지 못했어요") { send(.retryTapped) }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        TabView(selection: $store.selectedTab.sending(\.view.tabSelected)) {
          ScrollView { homePage().padding(16) }.tag(ClassOwnerTab.home)
          ScrollView { reportPage().padding(16) }.tag(ClassOwnerTab.report)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { send(.onAppear) }
    .pickeModal($store.scope(state: \.management, action: \.management), dimOpacity: 0.28) { _ in
      ZStack(alignment: .bottom) {
        Color.clear
          .ignoresSafeArea()
          .contentShape(Rectangle())
          .onTapGesture { send(.managementDismissed) }
        ClassManagementSheet(
          room: store.room,
          onEdit: { send(.managementEditTapped) },
          onDelete: { send(.managementDeleteTapped) }
        )
        .frame(maxWidth: .infinity)
        .background(
          UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
            .fill(.beige50)
            .ignoresSafeArea(edges: .bottom)
        )
      }
    }
  }
}

private extension ClassOwnerDashboardView {
  @ViewBuilder
  func sourceSkeleton() -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        SkeletonView(.round(cornerRadius: 2)).frame(height: 120)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 150, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 180)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 150, height: 18)
        SkeletonView(.round(cornerRadius: 2)).frame(height: 180)
      }
      .padding(16)
    }
    .accessibilityLabel("클래스 현황을 불러오는 중")
  }

  @ViewBuilder
  func insightStatus() -> some View {
    switch store.insightViewState {
    case .loading:
      VStack(alignment: .leading, spacing: 10) {
        SkeletonView(.round(cornerRadius: 2)).frame(height: 14)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 220, height: 14)
      }
      .accessibilityLabel("AI 인사이트를 불러오는 중")
    case .pending:
      unavailableContent("AI 인사이트를 정리하고 있어요. 잠시 뒤 다시 확인해 주세요.")
    case .retryableFailure:
      PickeRetryErrorView(message: "AI 인사이트를 불러오지 못했어요") { send(.insightRetryTapped) }
    case .failure:
      unavailableContent("AI 인사이트를 표시할 수 없어요")
    case .unavailable:
      unavailableContent("AI 인사이트를 사용할 수 없어요")
    case .ready:
      EmptyView()
    }
  }

  @ViewBuilder
  func feedbackStatus() -> some View {
    switch store.feedbackViewState {
    case .loading:
      VStack(alignment: .leading, spacing: 10) {
        SkeletonView(.round(cornerRadius: 2)).frame(height: 14)
        SkeletonView(.round(cornerRadius: 2)).frame(width: 220, height: 14)
      }
      .accessibilityLabel("AI 피드백을 불러오는 중")
    case .pending:
      unavailableContent("AI 피드백을 정리하고 있어요. 잠시 뒤 다시 확인해 주세요.")
    case .retryableFailure:
      PickeRetryErrorView(message: "AI 피드백을 불러오지 못했어요") { send(.feedbackRetryTapped) }
    case .failure:
      unavailableContent("AI 피드백을 표시할 수 없어요")
    case .unavailable:
      unavailableContent("AI 피드백을 사용할 수 없어요")
    case .ready:
      EmptyView()
    }
  }

  var navigationBar: some View {
    ClassReportNavigationBar(
      title: store.room.name,
      backAccessibilityIdentifier: "class-owner-report-back",
      onBack: { send(.backTapped) }
    )
  }

  @ViewBuilder
  func titleHeader() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        statusBadge()
        if !store.room.battle.categoryDisplayTitle.isEmpty {
          Text("#\(store.room.battle.categoryDisplayTitle)")
            .pickeBadge(.filled, size: .tag)
        }
      }
      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(store.deadlineText)
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)
    }
    .padding(.horizontal, 16)
    .frame(height: 118, alignment: .center)
  }

  @ViewBuilder
  func statusBadge() -> some View {
    switch store.room.status {
    case .open:
      Text("진행 중")
        .pickeBadge(.filled, size: .tag)
    case .closed:
      Text("종료")
        .pretendardFont(.semiBold12)
        .foregroundStyle(.gray300)
        .padding(.horizontal, 4)
        .frame(height: 20)
        .roundedBackground(.gray50, radius: 2)
    }
  }

  @ViewBuilder
  func dashboardTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassOwnerTab.allCases, id: \.self) { tab in
        Button { send(.tabSelected(tab)) } label: {
          Text(tab.rawValue)
            .pretendardFont(family: .Medium, size: 13)
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
        .accessibilityIdentifier("class-owner-tab.\(tab.rawValue)")
      }
    }
  }

  var insightLinePadding: CGFloat {
    max(0, 12 * 1.4 - UIFont.pretendardFontFamily(family: .Regular, size: 12).lineHeight)
  }

  @ViewBuilder
  func homePage() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      if let result = store.classResult {
        serverHomePage(result)
      } else {
        if case let .ready(insight) = store.insightViewState {
          VStack(alignment: .leading, spacing: 6) {
            ClassAIInsightHeading(
              title: "AI 인사이트",
              titleFont: .bold11,
              titleLineHeight: 15.4,
              iconSize: 20,
              spacing: 6
            )
            Text(insight)
              .pretendardFont(.bodySmall)
              .lineSpacing(insightLinePadding)
              .padding(.vertical, insightLinePadding / 2)
          }
          .foregroundStyle(.primary500)
          .padding(13)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(hex: "FCF5F3"), in: RoundedRectangle(cornerRadius: 2))
          .overlay(RoundedRectangle(cornerRadius: 2).stroke(.primary100, lineWidth: 1))
        } else {
          dashboardSection("AI 인사이트") {
            insightStatus()
          }
        }
        dashboardSection("클래스 참여 현황") {
          if let metrics = store.metrics {
            let total = store.members.count
            let participated = store.members.filter { $0.participationCount > 0 }.count
            VStack(spacing: 12) {
              participationRow(
                "배틀 참여율",
                value: percentage(participated, of: total),
                detail: "참여한 멤버",
                count: "\(participated) / \(total)명",
                progress: ratio(participated, of: total),
                tint: .primary500
              )
              participationRow(
                "댓글 작성율",
                value: percentage(metrics.commentAuthorCount, of: total),
                detail: "댓글을 남긴 멤버",
                count: "\(metrics.commentAuthorCount) / \(total)명",
                progress: ratio(metrics.commentAuthorCount, of: total),
                tint: .secondary500
              )
            }
            .frame(height: 152)
            .padding(.horizontal, 17)
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
            .onAppear(perform: animateChartsIfNeeded)
          } else {
            unavailableContent("참여 현황을 불러올 수 없어요")
          }
        }
        dashboardSection("입장 분포") {
          if let metrics = store.metrics {
            let total = metrics.optionAVoteCount + metrics.optionBVoteCount
            let optionAShare = ratio(metrics.optionAVoteCount, of: total)
            HStack(spacing: 20) {
              ZStack {
                Circle().stroke(.beige600, lineWidth: 11)
                ClassDistributionSegment(start: 0, end: optionAShare, progress: chartProgress)
                  .stroke(.primary500, style: StrokeStyle(lineWidth: 11, lineCap: .butt))
                ClassDistributionSegment(
                  start: optionAShare,
                  end: total > 0 ? 1 : 0,
                  progress: chartProgress
                )
                .stroke(.secondary500, style: StrokeStyle(lineWidth: 11, lineCap: .butt))
                VStack(spacing: 0) {
                  Text("\(total)명")
                    .pretendardFont(.labelLarge)
                    .frame(minHeight: 24)
                  Text("총 참여")
                    .pretendardFont(.medium10)
                    .foregroundStyle(.gray300)
                    .frame(minHeight: 14)
                }
              }
              .frame(width: 92, height: 92)
              VStack(alignment: .leading, spacing: 14) {
                stanceLegendRow(
                  store.room.battle.optionATitle,
                  count: metrics.optionAVoteCount,
                  total: total,
                  tint: .primary500
                )
                stanceLegendRow(
                  store.room.battle.optionBTitle,
                  count: metrics.optionBVoteCount,
                  total: total,
                  tint: .secondary500
                )
              }
            }
            .foregroundStyle(.gray700)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 134)
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
          } else {
            unavailableContent("입장 분포를 불러올 수 없어요")
          }
        }
        dashboardSection("주요 의견") {
          switch store.topOpinionViewState {
          case .empty:
            unavailableContent("등록된 의견이 없어요")
          case .unavailable:
            unavailableContent("주요 의견을 집계할 수 없어요")
          case let .loaded(opinions):
            topOpinionCard(opinions)
          }
        }
      }
    }
  }

  @ViewBuilder
  func serverHomePage(_ result: ClassResult) -> some View {
    dashboardSection("AI 인사이트") {
      if case let .ready(insight) = store.insightViewState {
        serverInsightContent(insight)
      } else {
        insightStatus()
      }
    }
    dashboardSection("클래스 참여 현황") {
      VStack(spacing: 12) {
        participationRow(
          "배틀 참여율",
          value: store.serverParticipationRate,
          detail: "참여를 완료한 멤버",
          count: store.serverParticipationCount,
          progress: CGFloat(store.serverParticipationProgress),
          tint: .primary500
        )
        participationRow(
          "댓글 작성율",
          value: store.serverCommentRate,
          detail: "댓글을 남긴 멤버",
          count: store.serverCommentCount,
          progress: CGFloat(store.serverCommentProgress),
          tint: .secondary500
        )
      }
      .padding(16)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .onAppear(perform: animateChartsIfNeeded)
    }
    dashboardSection("입장 분포") {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(result.stats.options, id: \.id) { option in
          HStack {
            Text(option.title)
            Spacer()
            Text(store.serverOptionSummary(option))
          }
          .pretendardFont(.semiBold12)
          .foregroundStyle(.gray800)
        }
      }
      .padding(16)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    }
    dashboardSection("주요 의견") {
      if let highlights = store.serverInsight?.highlights, !highlights.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(highlights.indices, id: \.self) { index in
            Text(highlights[index].content)
              .pretendardFont(.regular13)
              .foregroundStyle(.gray700)
          }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      } else {
        unavailableContent("대표 의견이 없어요")
      }
    }
  }

  @ViewBuilder
  func serverInsightContent(_ insight: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(insight)
        .foregroundStyle(.primary500)
      if let detail = store.serverInsight {
        if let coverage = detail.coverageDescription {
          Text(coverage)
            .foregroundStyle(.gray700)
        }
        ForEach(detail.evidence.indices, id: \.self) { index in
          Text(detail.evidence[index].quote ?? detail.evidence[index].content)
            .foregroundStyle(.gray700)
        }
      }
    }
    .pretendardFont(.bodySmall)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func reportPage() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      if let classResult = store.classResult {
        dashboardSection("AI 인사이트") {
          if case let .ready(insight) = store.insightViewState {
            serverInsightContent(insight)
          } else {
            insightStatus()
          }
        }
        dashboardSection("내 투표 결과") {
          if classResult.myReportState == nil {
            unavailableContent("참여하지 않은 운영자에게 개인 투표 결과는 제공되지 않아요")
          } else if case let .ready(feedback) = store.feedbackViewState {
            serverPersonalVoteContent(feedback)
          } else {
            feedbackStatus()
          }
        }
        if classResult.myReportState != nil {
          dashboardSection("AI 피드백") {
            if case let .ready(feedback) = store.feedbackViewState {
              serverPersonalFeedbackContent(feedback)
            } else {
              feedbackStatus()
            }
          }
        }
      } else {
        dashboardSection("내 투표 결과") {
          if let content = store.report {
            VStack(spacing: 16) {
              HStack(spacing: 8) {
                reportChoice("사전 선택", value: content[.initialChoice])
                Text("입장 변경")
                  .pretendardFont(family: .SemiBold, size: 10)
                  .foregroundStyle(.beige50)
                  .frame(minHeight: 14)
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(.primary500, in: Capsule())
                reportChoice("사후 선택", value: content[.finalChoice])
              }
              .padding(.vertical, 12)
              .background(.beige300, in: RoundedRectangle(cornerRadius: 2))

              HStack(spacing: 0) {
                reportActivity(content[.commentCount], label: "댓글")
                Rectangle().fill(.beige600).frame(width: 1, height: 36)
                reportActivity(content[.replyCount], label: "대댓글")
                Rectangle().fill(.beige600).frame(width: 1, height: 36)
                reportActivity(content[.receivedLikeCount], label: "받은 추천")
              }
            }
            .padding(16)
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
          } else {
            unavailableContent("내 투표와 참여 기록을 불러올 수 없어요")
          }
        }

        dashboardSection("AI 피드백") {
          if case let .ready(feedback) = store.feedbackViewState {
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
                  .lineSpacing(insightLinePadding)
                  .padding(.vertical, insightLinePadding / 2)
              }
              .foregroundStyle(.primary500)
              .padding(16)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(Color(hex: "FCF5F3"))

              VStack(alignment: .leading, spacing: 16) {
                ForEach(feedback.points.indices, id: \.self) { index in
                  if index > 0 {
                    Rectangle().fill(.beige600).frame(height: 1)
                  }
                  reportInsight(feedback.points[index].title, detail: feedback.points[index].detail)
                }
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
                if store.report != nil {
                  Rectangle().fill(.beige600).frame(height: 1)
                  myOpinionsButton
                }
              }
              .padding(16)
            }
            .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
          } else {
            feedbackStatus()
            if store.report != nil {
              myOpinionsButton
                .padding(16)
                .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
            }
          }
        }
      }
    }
  }

  @ViewBuilder
  func serverPersonalVoteContent(_ feedback: ClassAIPersonalFeedback) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        reportChoice("사전 선택", value: feedback.preOption?.title ?? "선택 없음")
        reportChoice("사후 선택", value: feedback.postOption?.title ?? "선택 없음")
      }
      HStack(spacing: 0) {
        reportActivity("\(feedback.perspectiveCount)", label: "의견")
        Rectangle().fill(.beige600).frame(width: 1, height: 36)
        reportActivity("\(feedback.commentCount)", label: "댓글")
      }
    }
    .padding(16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func serverPersonalFeedbackContent(_ feedback: ClassAIPersonalFeedback) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(feedback.summaryTitle)
        .pretendardFont(.semiBold15)
      Text(feedback.summaryDetail)
        .pretendardFont(.bodySmall)
      ForEach(feedback.points.indices, id: \.self) { index in
        reportInsight(feedback.points[index].title, detail: feedback.points[index].detail)
      }
      if !feedback.nextQuestion.isEmpty {
        reportInsight("다음 생각", detail: feedback.nextQuestion)
      }
      if let coverage = feedback.coverageDescription {
        Text(coverage).pretendardFont(.regular13)
      }
      ForEach(feedback.evidence.indices, id: \.self) { index in
        Text(feedback.evidence[index].quote ?? feedback.evidence[index].content)
          .pretendardFont(.regular13)
      }
      myOpinionsButton
    }
    .padding(16)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
  }

  @ViewBuilder
  func reportChoice(
    _ label: String,
    value: String
  ) -> some View {
    VStack(spacing: 4) {
      Text(label).pretendardFont(.medium11).foregroundStyle(.gray300).frame(minHeight: 15)
      Text(value).pretendardFont(.semiBold12).foregroundStyle(.gray800).frame(minHeight: 17)
    }
    .frame(maxWidth: .infinity)
  }

  var myOpinionsButton: some View {
    Button { send(.myOpinionsTapped) } label: {
      HStack {
        Text(store.myOpinionsTitle)
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
    .accessibilityIdentifier("class-owner-my-opinions")
  }

  @ViewBuilder
  func reportActivity(
    _ count: String,
    label: String
  ) -> some View {
    VStack(spacing: 0) {
      Text(count).pretendardFont(.labelLarge).foregroundStyle(.gray800).frame(minHeight: 24)
      Text(label).pretendardFont(.medium10).foregroundStyle(.gray300).frame(minHeight: 14)
    }
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func reportInsight(
    _ label: String,
    detail: String
  ) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).pretendardFont(.semiBold12).foregroundStyle(.primary500).frame(minHeight: 17)
      Text(detail)
        .pretendardFont(.regular13)
        .foregroundStyle(.textSubtler)
        .lineSpacing(opinionLinePadding)
        .padding(.vertical, opinionLinePadding / 2)
    }
  }

  @ViewBuilder
  func dashboardSection(
    _ title: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .pretendardFont(.headingSmall)
        .foregroundStyle(.gray800)
        .frame(minHeight: 20)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  func animateChartsIfNeeded() {
    guard chartProgress == 0 else { return }
    guard !reduceMotion else {
      chartProgress = 1
      return
    }
    withAnimation(.easeOut(duration: 0.8)) { chartProgress = 1 }
  }

  func ratio(_ count: Int, of total: Int) -> CGFloat {
    guard total > 0 else { return 0 }
    return CGFloat(count) / CGFloat(total)
  }

  func percentage(_ count: Int, of total: Int) -> String {
    guard total > 0 else { return "0%" }
    return "\((Double(count) / Double(total) * 100).formatted(.number.precision(.fractionLength(0 ... 1))))%"
  }

  func roundedPercentage(_ count: Int, of total: Int) -> String {
    guard total > 0 else { return "0%" }
    return "\(Int((Double(count) / Double(total) * 100).rounded()))%"
  }

  func unavailableContent(_ message: String) -> some View {
    Text(message)
      .pretendardFont(.regular13)
      .foregroundStyle(.gray500)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 88)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  func participationRow(
    _ title: String,
    value: String,
    detail: String,
    count: String,
    progress: CGFloat,
    tint: Color
  ) -> some View {
    VStack(spacing: 4) {
      HStack {
        Text(title).pretendardFont(.semiBold12)
        Spacer()
        Text(value).pretendardFont(.headingSmall)
      }
      .frame(minHeight: 20)
      HStack {
        Text(detail)
        Spacer()
        Text(count)
      }
      .pretendardFont(.regular11)
      .foregroundStyle(.gray300)
      .frame(minHeight: 16)
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(.beige600)
          Capsule().fill(tint).frame(width: geometry.size.width * progress * chartProgress)
        }
      }
      .frame(height: 6)
    }
    .foregroundStyle(.gray800)
    .frame(height: 51)
  }

  @ViewBuilder
  func stanceLegendRow(
    _ title: String,
    count: Int,
    total: Int,
    tint: Color
  ) -> some View {
    HStack(alignment: .center, spacing: 8) {
      Circle().fill(tint).frame(width: 8, height: 8)
      VStack(alignment: .leading, spacing: 0) {
        Text(title)
          .pretendardFont(.semiBold12)
          .foregroundStyle(.gray800)
          .frame(minHeight: 17)
        Text("\(count)명")
          .pretendardFont(.medium11)
          .foregroundStyle(.gray300)
          .frame(minHeight: 16)
      }
      Spacer(minLength: 8)
      Text(roundedPercentage(count, of: total))
        .pretendardFont(family: .Bold, size: 12)
        .foregroundStyle(.gray800)
    }
  }

  var opinionLinePadding: CGFloat {
    max(0, 13 * 1.4 - UIFont.pretendardFontFamily(family: .Regular, size: 13).lineHeight)
  }

  private func opinionBadge(_ title: String) -> some View {
    Text(title)
      .pretendardFont(.semiBold12)
      .foregroundStyle(.primary500)
      .lineLimit(1)
      .frame(minHeight: 17)
      .padding(.horizontal, 4)
      .padding(.vertical, 1.5)
      .roundedBackground(.badgeFilledBackground)
  }

  @ViewBuilder
  func topOpinionCard(_ opinions: [ClassOwnerOpinion]) -> some View {
    VStack(spacing: 0) {
      ForEach(opinions.indices, id: \.self) { index in
        let opinion = opinions[index]
        if index > 0 {
          Rectangle().fill(.beige600).frame(height: 1)
        }
        VStack(alignment: .leading, spacing: 8) {
          opinionBadge(index == 0 ? "BEST 댓글" : "가장 논쟁이 활발했던 댓글")
          Text("“\(opinion.text)”")
            .pretendardFont(.regular13)
            .foregroundStyle(.textBody)
            .lineSpacing(opinionLinePadding)
            .padding(.vertical, opinionLinePadding / 2)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
      }
    }
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }
}

private struct ClassDistributionSegment: Shape {
  let start: CGFloat
  let end: CGFloat
  var progress: CGFloat

  var animatableData: CGFloat {
    get { progress }
    set { progress = newValue }
  }

  func path(in rect: CGRect) -> Path {
    let visibleEnd = min(end, max(start, progress))
    return Path(ellipseIn: rect).trimmedPath(from: start, to: visibleEnd)
  }
}

#if DEBUG
  #Preview("운영자 대시보드 · 요약") {
    ClassOwnerDashboardView(store: Store(initialState: .init(room: ClassRoom.mocks[0])) {
      ClassOwnerDashboardFeature()
    })
  }

  #Preview("운영자 대시보드 · 내 리포트") {
    let state = {
      var state = ClassOwnerDashboardFeature.State(room: ClassRoom.mocks[0])
      state.selectedTab = .report
      return state
    }()
    ClassOwnerDashboardView(store: Store(initialState: state) {
      ClassOwnerDashboardFeature()
    })
  }
#endif
