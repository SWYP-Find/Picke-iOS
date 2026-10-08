import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: ClassMemberFeature.self)
public struct ClassMemberView: View {
  @Bindable public var store: StoreOf<ClassMemberFeature>

  public init(store: StoreOf<ClassMemberFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "클래스 멤버")
        .foregroundStyle(.gray500)

      searchField
        .padding(.horizontal, 16)
        .padding(.top, 12)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          Text("멤버 \(store.room.memberCount)")
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.gray300)
            .padding(.bottom, 4)

          switch store.viewState {
          case .unavailable:
            Text("멤버 목록을 불러올 수 없어요.")
              .pretendardFont(family: .Medium, size: 14)
              .foregroundStyle(.gray300)
              .frame(maxWidth: .infinity)
              .padding(.top, 72)
          case .noSearchResults:
            Text("검색 결과가 없어요.")
              .pretendardFont(family: .Medium, size: 14)
              .foregroundStyle(.gray300)
              .frame(maxWidth: .infinity)
              .padding(.top, 72)
          case let .members(members):
            ForEach(members) { member in
              memberRow(member)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .pickeModal(
      $store.scope(state: \.filter, action: \.filter),
      dimOpacity: 0.28
    ) { filterStore in
      filterSheet(store: filterStore)
    }
    .pickeModal(
      $store.scope(state: \.editName, action: \.editName),
      dimOpacity: 0.28
    ) { editNameStore in
      nameSheet(store: editNameStore)
    }
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
  }
}

#if DEBUG
  #Preview("클래스 멤버") {
    ClassMemberView(store: Store(initialState: .preview(room: ClassRoom.mocks[0])) {
      ClassMemberFeature()
    })
  }
#endif

private extension ClassMemberView {
  var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18))
        .foregroundStyle(.gray300)
      TextField("이름을 입력해주세요.", text: $store.searchText)
        .pretendardFont(family: .Medium, size: 13)
        .foregroundStyle(.gray800)

      Button { send(.filterTapped) } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.gray500)
          .frame(width: 32, height: 32)
      }
      .accessibilityLabel("멤버 필터")
    }
    .padding(.horizontal, 12)
    .frame(height: 44)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func memberRow(_ member: ClassMember) -> some View {
    HStack(spacing: 12) {
      PickeAvatarView(imageURL: nil, fallback: member.name, size: 36)

      Text(member.name)
        .pretendardFont(family: .Medium, size: 16)
        .foregroundStyle(.gray800)

      if member.id == store.currentMemberID {
        Button { send(.editNameTapped(member.id)) } label: {
          Image(systemName: "pencil")
            .font(.system(size: 14))
            .foregroundStyle(.gray800)
        }
        .accessibilityLabel("내 이름 수정")
      }

      Spacer(minLength: 0)

      if member.isOwner {
        Text("운영자")
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
      } else if store.room.role == .owner, member.id != store.currentMemberID {
        Button { send(.removeTapped(member.id)) } label: {
          Image(systemName: "minus.circle.fill")
            .font(.system(size: 18))
            .foregroundStyle(.gray100)
        }
        .accessibilityLabel("\(member.name) 내보내기")
      }
    }
    .frame(height: 68)
    .overlay(alignment: .bottom) { Rectangle().fill(.beige600).frame(height: 1) }
  }

  @ViewBuilder
  func filterSheet(store: StoreOf<ClassMemberFilterFeature>) -> some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { store.send(.dismissTapped) }

      VStack(alignment: .leading, spacing: 20) {
        sheetHandle
        filterSection(
          title: "참여 상태",
          detail: "제공 예정",
          options: ClassMemberParticipation.allCases.filter { $0 != .all },
          selected: { store.participation == $0 },
          action: { store.send(.participationSelected($0)) },
          enabled: { _ in false }
        )
        filterSection(
          title: "미완료",
          detail: "제공 예정",
          options: ClassMemberCompletion.allCases.filter { $0 != .all },
          selected: { store.completion == $0 },
          action: { store.send(.completionSelected($0)) },
          enabled: { _ in false }
        )
        filterSection(
          title: "입장 변화",
          detail: "제공 예정",
          options: ClassMemberAttendance.allCases.filter { $0 != .all },
          selected: { store.attendance == $0 },
          action: { store.send(.attendanceSelected($0)) },
          enabled: { _ in false }
        )
        filterSection(
          title: "정렬",
          detail: "이름순만 제공",
          options: ClassMemberSort.allCases,
          selected: { store.sort == $0 },
          action: { store.send(.sortSelected($0)) },
          enabled: { $0 == .name }
        )

        Button { store.send(.applyTapped) } label: {
          Text("적용하기")
        }
        .ctaButtonStyle(.primary, size: .large, height: 52)
      }
      .padding(.top, 12)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
      .frame(maxWidth: .infinity)
      .background(
        UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
          .fill(.beige50)
          .ignoresSafeArea(edges: .bottom)
      )
    }
  }

  @ViewBuilder
  func filterSection<Option: RawRepresentable & Hashable>(
    title: String,
    detail: String,
    options: [Option],
    selected: @escaping (Option) -> Bool,
    action: @escaping (Option) -> Void,
    enabled: @escaping (Option) -> Bool
  ) -> some View where Option.RawValue == String {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Text(title)
          .pretendardFont(family: .SemiBold, size: 13)
          .foregroundStyle(.gray800)
        Spacer(minLength: 0)
        Text(detail)
          .pretendardFont(family: .Medium, size: 10)
          .foregroundStyle(.gray300)
      }

      HStack(spacing: 8) {
        ForEach(options, id: \.self) { option in
          Button { action(option) } label: {
            Text(option.rawValue)
              .pretendardFont(family: .Medium, size: 13)
              .foregroundStyle(selected(option) ? .beige50 : .gray300)
              .opacity(enabled(option) ? 1 : 0.5)
              .lineLimit(1)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.horizontal, 12)
              .frame(height: 30)
              .background(selected(option) ? .primary500 : .beige200, in: RoundedRectangle(cornerRadius: 2))
          }
          .buttonStyle(.plain)
          .disabled(!enabled(option))
        }
        Spacer(minLength: 0)
      }
    }
  }

  var sheetHandle: some View {
    Capsule()
      .fill(.gray50)
      .frame(width: 40, height: 4)
      .frame(maxWidth: .infinity)
      .padding(.bottom, 10)
  }

  @ViewBuilder
  func nameSheet(store editNameStore: StoreOf<ClassMemberEditNameFeature>) -> some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { editNameStore.send(.dismissTapped) }

      VStack(alignment: .leading, spacing: 20) {
        sheetHandle
        VStack(alignment: .leading, spacing: 6) {
          Text("이름을 입력해주세요")
            .pretendardFont(.semiBold24)
            .foregroundStyle(.gray800)
          Text("이 클래스에서만 보이는 이름이에요.")
            .pretendardFont(.regular13)
            .foregroundStyle(.gray300)
        }

        TextField("이름을 입력해주세요", text: $store.draftName)
          .textInputAutocapitalization(.never)
          .pickeTextField(height: 52)

        Button("수정하기") { send(.nameSaved) }
          .disabled(store.isSaving)
          .ctaButtonStyle(.primary, size: .large, height: 52)
          .disabled(store.draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(.top, 12)
      .padding(.horizontal, 16)
      .padding(.bottom, 32)
      .frame(maxWidth: .infinity)
      .background(
        UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26)
          .fill(.beige50)
          .ignoresSafeArea(edges: .bottom)
      )
    }
  }
}
