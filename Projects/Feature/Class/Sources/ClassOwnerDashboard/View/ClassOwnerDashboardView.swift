import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

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
      summaryHeader()
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
    .toolbar(.visible, for: .tabBar)
  }
}

private extension ClassOwnerDashboardView {
  @ViewBuilder
  func titleHeader() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("예시 데이터")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)
      Text(store.room.battle.title)
        .pretendardFont(.semiBold24)
        .foregroundStyle(.gray800)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text("참여 멤버 \(store.room.memberCount)명")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray500)
    }
    .padding(.horizontal, 16)
    .frame(height: 166, alignment: .center)
  }

  @ViewBuilder
  func summaryHeader() -> some View {
    VStack(spacing: 10) {
      HStack {
        Text("플라톤")
        Text("59.5%")
        Spacer()
        Text("찬성")
        Text("반대 40.5%")
      }
      .pretendardFont(family: .Medium, size: 12)
      .foregroundStyle(.gray500)
      GeometryReader { proxy in
        HStack(spacing: 0) {
          RoundedRectangle(cornerRadius: 3).fill(.primary500).frame(width: proxy.size.width * 0.595)
          RoundedRectangle(cornerRadius: 3).fill(.secondary500)
        }
      }
      .frame(height: 6)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
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
    VStack(alignment: .leading, spacing: 16) {
      dashboardSection("클래스 참여 현황", trailing: "총 47회 참여") {
        HStack(spacing: 8) {
          metric("참여 학생", value: "28명")
          metric("평균 참여", value: "59.5%")
          metric("미참여", value: "4명")
        }
      }
      dashboardSection("입장 분포", trailing: "총 47회 참여") {
        HStack(spacing: 10) {
          distribution("찬성", value: "59.5%", color: .primary500)
          distribution("반대", value: "40.5%", color: .secondary500)
        }
      }
      dashboardSection("확인이 필요한 멤버", trailing: "총 47회 참여") {
        ForEach(store.members.filter(\.needsReview)) { memberRow($0, action: "피드백") }
      }
      dashboardSection("참여도가 높은 멤버", trailing: "총 47회 참여") {
        ForEach(store.members.sorted { $0.participationCount > $1.participationCount }.prefix(2)) { member in
          memberRow(member, action: "상세")
        }
      }
      dashboardSection("주요 의견", trailing: "총 47회 참여") {
        ForEach(store.opinions.prefix(2)) { opinion in opinionRow(opinion) }
      }
    }
  }

  @ViewBuilder
  func membersPage() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("멤버 \(store.room.memberCount)")
        .pretendardFont(.semiBold15).foregroundStyle(.gray800)
      TextField("멤버 검색", text: Binding(
        get: { store.searchText },
        set: { send(.searchTextChanged($0)) }
      ))
      .pretendardFont(.regular13)
      .padding(.horizontal, 12).frame(height: 40)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
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
      ForEach(store.visibleMembers) { member in
        memberRow(member, action: member.needsReview ? "피드백" : "상세")
      }
    }
  }

  @ViewBuilder
  func opinionsPage() -> some View {
    VStack(alignment: .leading, spacing: 12) {
      opinionFilters()
      ForEach(store.visibleOpinions) { opinion in opinionRow(opinion) }
    }
  }

  @ViewBuilder
  func opinionFilters() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        ForEach(ClassOwnerOpinionFilter.allCases, id: \.self) { filter in
          Button { send(.opinionFilterSelected(filter)) } label: {
            Text(filter.rawValue).pickeSortChip(isSelected: store.opinionFilter == filter)
          }.buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  func dashboardSection(
    _ title: String,
    trailing: String,
    @ViewBuilder content: () -> some View
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(title).pretendardFont(.semiBold15).foregroundStyle(.gray800)
        Spacer()
        Text(trailing).pretendardFont(.regular10).foregroundStyle(.gray300)
      }
      content()
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func metric(_ title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).pretendardFont(.regular10).foregroundStyle(.gray300)
      Text(value).pretendardFont(.semiBold15).foregroundStyle(.gray800)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  func distribution(_ title: String, value: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack { Circle().fill(color).frame(width: 7, height: 7); Text(title); Spacer(); Text(value) }
        .pretendardFont(.regular13).foregroundStyle(.gray500)
      ProgressView(value: title == "찬성" ? 0.595 : 0.405).tint(color)
    }.frame(maxWidth: .infinity)
  }

  @ViewBuilder
  func memberRow(_ member: ClassOwnerMember, action: String) -> some View {
    Button {
      send(member.needsReview ? .feedbackTapped(member.id) : .memberTapped(member.id))
    } label: {
      HStack(spacing: 10) {
        Text(String(member.name.prefix(1))).pickeAvatarFallback(size: 32).pickeAvatar(size: 32)
        VStack(alignment: .leading, spacing: 2) {
          Text(member.name).pretendardFont(.medium13).foregroundStyle(.gray700)
          Text("배틀 참여 \(member.participationCount)회").pretendardFont(.regular10).foregroundStyle(.gray300)
        }
        Spacer()
        Text(action).pretendardFont(family: .Bold, size: 12).foregroundStyle(.primary500)
      }
      .padding(.vertical, 7)
    }.buttonStyle(.plain)
  }

  @ViewBuilder
  func opinionRow(_ opinion: ClassOwnerOpinion) -> some View {
    Button { send(.opinionTapped(opinion.id)) } label: {
      VStack(alignment: .leading, spacing: 7) {
        HStack {
          Text(opinion.author).pretendardFont(.medium13).foregroundStyle(.gray500)
          Spacer()
          if opinion.isReported {
            Text("신고").pretendardFont(.regular10).foregroundStyle(.errorDefault)
          }
        }
        Text(opinion.text)
          .pretendardFont(.regular13)
          .foregroundStyle(.gray700)
          .multilineTextAlignment(.leading)
        Text("대댓글 \(opinion.replyCount)개").pretendardFont(.regular10).foregroundStyle(.gray300)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
      .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
    }.buttonStyle(.plain)
  }
}
