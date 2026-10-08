import ClassDomainInterface
import ComposableArchitecture
import Foundation
import PickeDesignKit
import SwiftUI

private enum MemberRowAction: String {
  case detail = "상세"
  case feedback = "피드백"
}

@ViewAction(for: ClassOwnerDashboardFeature.self)
public struct ClassOwnerDashboardView: View {
  @Bindable public var store: StoreOf<ClassOwnerDashboardFeature>

  public init(store: StoreOf<ClassOwnerDashboardFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: store.room.name)
        .foregroundStyle(.gray800)

      titleHeader()
      dashboardTabs()
      TabView(selection: Binding(
        get: { store.selectedTab },
        set: { send(.tabSelected($0)) }
      )) {
        ScrollView { homePage().padding(16) }.tag(ClassOwnerTab.home)
        ScrollView { membersPage().padding(16) }.tag(ClassOwnerTab.members)
        ScrollView { opinionsPage().padding(16) }.tag(ClassOwnerTab.opinions)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
  }
}

private extension ClassOwnerDashboardView {
  @ViewBuilder
  func titleHeader() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text(store.room.status == .open ? "진행 중" : "종료")
          .foregroundStyle(.primary500)
        Text("#\(store.room.battle.category.title)")
          .foregroundStyle(.gray500)
      }
      .pretendardFont(.medium13)
      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text("\(Self.deadlineFormatter.string(from: store.room.deadline))까지")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray500)
    }
    .padding(.horizontal, 16)
    .frame(height: 118, alignment: .center)
  }

  static let deadlineFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy. MM. dd. EEEE HH:mm"
    return formatter
  }()

  static let opinionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yy.MM.dd. HH:mm"
    return formatter
  }()

  @ViewBuilder
  func dashboardTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(ClassOwnerTab.allCases, id: \.self) { tab in
        Button { send(.tabSelected(tab)) } label: {
          Text(tab == .home ? "요약" : tab.rawValue)
            .pretendardFont(family: .Medium, size: 13)
            .foregroundStyle(store.selectedTab == tab ? .primary500 : .gray300)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
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
  func homePage() -> some View {
    VStack(alignment: .leading, spacing: 24) {
      dashboardSection("클래스 참여 현황") {
        if let metrics = previewMetrics {
          let total = store.members.count
          let participated = store.members.filter { $0.participationCount > 0 }.count
          VStack(spacing: 12) {
            participationRow(
              "배틀 참여율",
              value: percentage(participated, of: total),
              detail: "참여한 멤버",
              count: "\(participated) / \(total)명",
              progress: ratio(participated, of: total)
            )
            participationRow(
              "댓글 작성율",
              value: percentage(metrics.commentAuthorCount, of: total),
              detail: "댓글을 남긴 멤버",
              count: "\(metrics.commentAuthorCount) / \(total)명",
              progress: ratio(metrics.commentAuthorCount, of: total)
            )
          }
          .frame(height: 152)
          .padding(.horizontal, 17)
          .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
          .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
        } else {
          unavailableContent("참여 현황을 불러올 수 없어요")
        }
      }
      dashboardSection("입장 분포") {
        if let metrics = previewMetrics {
          let total = metrics.optionAVoteCount + metrics.optionBVoteCount
          HStack(spacing: 20) {
            ZStack {
              Circle().stroke(.beige600, lineWidth: 11)
              Circle()
                .trim(from: 0, to: ratio(metrics.optionAVoteCount, of: total))
                .stroke(.primary500, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
              VStack(spacing: 0) {
                Text("\(total)명").pretendardFont(.semiBold24)
                Text("총 참여").pretendardFont(.regular10)
              }
            }
            .frame(width: 92, height: 92)
            VStack(alignment: .leading, spacing: 6) {
              Text(
                "\(store.room.battle.optionATitle)  \(metrics.optionAVoteCount)명 · \(roundedPercentage(metrics.optionAVoteCount, of: total))"
              )
              Text(
                "\(store.room.battle.optionBTitle)  \(metrics.optionBVoteCount)명 · \(roundedPercentage(metrics.optionBVoteCount, of: total))"
              )
            }
            .pretendardFont(.regular13)
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
      dashboardSection("확인이 필요한 멤버") {
        switch store.needsReviewViewState {
        case .unavailable:
          unavailableContent("멤버 활동 정보가 없어요")
        case .empty:
          unavailableContent("확인이 필요한 멤버가 없어요")
        case let .loaded(members):
          ForEach(members) { memberRow($0, action: .feedback) }
        }
      }
      dashboardSection("참여도가 높은 멤버") {
        switch store.highParticipationViewState {
        case .unavailable:
          unavailableContent("멤버 활동 정보가 없어요")
        case .empty:
          unavailableContent("아직 참여한 멤버가 없어요")
        case let .loaded(members):
          ForEach(members) { member in
            memberRow(member, action: .detail)
          }
        }
      }
      dashboardSection("주요 의견") {
        switch store.topOpinionViewState {
        case .empty:
          unavailableContent("등록된 의견이 없어요")
        case .unavailable:
          unavailableContent("주요 의견을 집계할 수 없어요")
        case let .loaded(opinions):
          ForEach(opinions) { opinion in opinionRow(opinion) }
        }
      }
    }
  }

  @ViewBuilder
  func membersPage() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.gray500)
        TextField("이름을 입력해주세요.", text: Binding(
          get: { store.searchText },
          set: { send(.searchTextChanged($0)) }
        ))
        .pretendardFont(.regular13)
      }
      .padding(.horizontal, 12)
      .frame(height: 44)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ClassOwnerDashboardFeature.MemberFilter.allCases, id: \.self) { filter in
            Button { send(.memberFilterSelected(filter)) } label: {
              Text(memberFilterTitle(filter))
                .pickeSortChip(isSelected: store.memberFilter == filter)
            }
            .buttonStyle(.plain)
            .disabled(store.members.isEmpty && filter != .all)
            .opacity(store.members.isEmpty && filter != .all ? 0.5 : 1)
          }
        }
      }
      Text(store.members.isEmpty ? "클래스 멤버 \(store.room.memberCount)" : "멤버 \(store.members.count)")
        .pretendardFont(.semiBold15).foregroundStyle(.gray800)
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(ClassOwnerMemberSort.allCases, id: \.self) { sort in
            Button { send(.memberSortSelected(sort)) } label: {
              Text(sort.rawValue).pickeSortChip(isSelected: store.memberSort == sort)
            }
            .buttonStyle(.plain)
          }
        }
      }
      switch store.memberViewState {
      case .unavailable:
        unavailableContent("멤버 활동 정보가 없어요")
      case .noSearchResults:
        unavailableContent("검색 결과가 없어요")
      case let .loaded(members):
        ForEach(members) { member in
          memberRow(member, action: member.needsReview ? .feedback : .detail)
        }
      }
    }
  }

  @ViewBuilder
  func opinionsPage() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      opinionFilters()
      switch store.opinionViewState {
      case .empty:
        unavailableContent("등록된 의견이 없어요")
      case let .loaded(opinions):
        ForEach(opinions) { opinion in opinionRow(opinion) }
      }
    }
  }

  @ViewBuilder
  func opinionFilters() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(ClassOwnerOpinionFilter.allCases, id: \.self) { filter in
          Button { send(.opinionFilterSelected(filter)) } label: {
            Text(filter.rawValue).pickeSortChip(isSelected: store.activeOpinionFilter == filter)
          }
          .buttonStyle(.plain)
          .disabled(!store.availableOpinionFilters.contains(filter))
          .opacity(store.availableOpinionFilters.contains(filter) ? 1 : 0.5)
        }
      }
    }
  }

  @ViewBuilder
  func dashboardSection(
    _ title: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  var usesPreviewContent: Bool {
    #if DEBUG
      store.usesPreviewContent
    #else
      false
    #endif
  }

  var previewMetrics: ClassOwnerDashboardFeature.State.PreviewMetrics? {
    #if DEBUG
      store.previewMetrics
    #else
      nil
    #endif
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

  func memberFilterTitle(_ filter: ClassOwnerDashboardFeature.MemberFilter) -> String {
    switch filter {
    case .all: return "전체"
    case .participated:
      return store.members.isEmpty
        ? "참여 완료"
        : "참여 완료 \(store.searchedMembers.filter { $0.participationCount > 0 }.count)"
    case .notParticipated:
      return store.members.isEmpty
        ? "미참여"
        : "미참여 \(store.searchedMembers.filter { $0.participationCount == 0 }.count)"
    }
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

  func participationRow(_ title: String, value: String, detail: String, count: String, progress: CGFloat) -> some View {
    VStack(spacing: 4) {
      HStack {
        Text(title).pretendardFont(.medium13)
        Spacer()
        Text(value).pretendardFont(.semiBold15)
      }
      HStack {
        Text(detail)
        Spacer()
        Text(count)
      }
      .pretendardFont(.regular10)
      .foregroundStyle(.gray500)
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule().fill(.beige600)
          Capsule().fill(.primary500).frame(width: geometry.size.width * progress)
        }
      }
      .frame(height: 6)
    }
    .foregroundStyle(.gray800)
    .frame(height: 51)
  }

  @ViewBuilder
  func memberRow(_ member: ClassOwnerMember, action: MemberRowAction) -> some View {
    HStack(spacing: 10) {
      Button { send(.memberTapped(member.id)) } label: {
        HStack(spacing: 10) {
          Text(String(member.name.prefix(1))).pickeAvatarFallback(size: 32).pickeAvatar(size: 32)
          VStack(alignment: .leading, spacing: 2) {
            Text(member.name).pretendardFont(.medium13).foregroundStyle(.gray700)
            Text("배틀 참여 \(member.participationCount)회").pretendardFont(.regular10).foregroundStyle(.gray300)
          }
          Spacer()
        }
      }
      .buttonStyle(.plain)

      Button {
        send(action == .feedback ? .feedbackTapped(member.id) : .memberTapped(member.id))
      } label: {
        Text(action.rawValue).pretendardFont(family: .Bold, size: 12).foregroundStyle(.primary500)
      }
      .buttonStyle(.plain)
    }
    .padding(.vertical, 7)
  }

  @ViewBuilder
  func opinionRow(_ opinion: ClassOwnerOpinion) -> some View {
    Button { send(.opinionTapped(opinion.id)) } label: {
      VStack(alignment: .leading, spacing: 7) {
        HStack {
          Text(String(opinion.author.prefix(1))).pickeAvatarFallback(size: 36).pickeAvatar(size: 36)
          VStack(alignment: .leading, spacing: 2) {
            Text(opinion.author).pretendardFont(.medium13).foregroundStyle(.gray500)
            if usesPreviewContent, let createdAt = opinion.createdAt {
              Text(Self.opinionDateFormatter.string(from: createdAt))
                .pretendardFont(.regular10)
                .foregroundStyle(.gray300)
            }
          }
          Spacer()
          if usesPreviewContent {
            Text(store.room.battle.optionATitle)
              .pretendardFont(.regular10)
              .foregroundStyle(.primary500)
              .padding(.horizontal, 4)
              .frame(height: 21)
              .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
          }
          if opinion.isReported {
            Text("신고").pretendardFont(.regular10).foregroundStyle(.errorDefault)
          }
        }
        Text(opinion.text)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
        Text("자세히 보기")
          .pretendardFont(.regular10)
          .foregroundStyle(.gray500)
        HStack(spacing: 16) {
          if let recommendationCount = opinion.recommendationCount {
            Text("추천 \(recommendationCount.formatted())")
          }
          Text("대댓글 \(opinion.replyCount)")
        }
        .pretendardFont(.regular10)
        .foregroundStyle(.gray300)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
    }.buttonStyle(.plain)
  }
}

#if DEBUG
  #Preview("운영자 대시보드 · 요약") {
    ClassOwnerDashboardView(store: Store(initialState: .preview(room: ClassRoom.mocks[0])) {
      ClassOwnerDashboardFeature()
    })
  }

  #Preview("운영자 대시보드 · 멤버") {
    ClassOwnerDashboardView(store: Store(initialState: .preview(room: ClassRoom.mocks[0], tab: .members)) {
      ClassOwnerDashboardFeature()
    })
  }

  #Preview("운영자 대시보드 · 의견") {
    ClassOwnerDashboardView(store: Store(initialState: .preview(room: ClassRoom.mocks[0], tab: .opinions)) {
      ClassOwnerDashboardFeature()
    })
  }
#endif
