//
//  ClassMemberView.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

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
      navigationBar()

      searchField()
        .padding(.horizontal, 16)
        .padding(.top, 12)

      ScrollView {
        LazyVStack(alignment: .leading, spacing: 0) {
          Text("멤버 \(store.room.memberCount)")
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.gray300)
            .padding(.bottom, 4)

          switch store.viewState {
          case .loading:
            memberSkeleton()
          case .error:
            loadError()
          case .empty:
            emptyMessage("아직 참여한 멤버가 없어요.")
          case .noSearchResults:
            emptyMessage("검색 결과가 없어요.")
          case .loaded:
            ForEach(store.visibleMembers) { member in
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
    .pickeModal($store.scope(state: \.management, action: \.management), dimOpacity: 0.28) { _ in
      managementSheet()
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
  @ViewBuilder
  func navigationBar() -> some View {
    PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "클래스 멤버") {
      if store.room.role == .owner {
        Button { send(.managementTapped) } label: {
          Image(systemName: "ellipsis")
            .pretendardFont(family: .SemiBold, size: 20)
            .frame(width: 24, height: 24)
            .foregroundStyle(.gray800)
        }
        .disabled(store.isSaving)
        .accessibilityLabel("클래스 관리")
      }
    }
    .foregroundStyle(.gray500)
  }

  @ViewBuilder
  func managementSheet() -> some View {
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

  @ViewBuilder
  func memberSkeleton() -> some View {
    VStack(spacing: 0) {
      ForEach(0 ..< 5, id: \.self) { _ in
        HStack(spacing: 12) {
          SkeletonView(.circle)
            .frame(width: 36, height: 36)
          SkeletonView(.round(cornerRadius: 2))
            .frame(width: 112, height: 18)
          Spacer(minLength: 0)
        }
        .frame(height: 68)
        .overlay(alignment: .bottom) { Rectangle().fill(.beige600).frame(height: 1) }
        .accessibilityHidden(true)
      }
    }
  }

  @ViewBuilder
  func loadError() -> some View {
    VStack(spacing: 12) {
      emptyMessage("멤버 목록을 불러올 수 없어요.")
      Button("다시 시도하기") { send(.retryTapped) }
        .pretendardFont(family: .SemiBold, size: 14)
        .foregroundStyle(.primary500)
    }
  }

  func emptyMessage(_ message: String) -> some View {
    Text(message)
      .pretendardFont(family: .Medium, size: 14)
      .foregroundStyle(.gray300)
      .frame(maxWidth: .infinity)
      .padding(.top, 72)
  }

  @ViewBuilder
  func searchField() -> some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .resizable()
        .scaledToFit()
        .frame(width: 18, height: 18)
        .foregroundStyle(.gray800)
      TextField(
        "이름을 입력해주세요.",
        text: $store.searchText,
        prompt: Text("이름을 입력해주세요.").foregroundStyle(.gray300)
      )
        .pretendardFont(family: .Medium, size: 13)
        .foregroundStyle(.gray800)
    }
    .padding(.horizontal, 12)
    .frame(height: 44)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.gray100, lineWidth: 1))
  }

  @ViewBuilder
  func memberRow(_ member: ClassMember) -> some View {
    HStack(spacing: 8) {
      if let avatar = member.avatar {
        memberAvatar(avatar)
      }

      Text(member.name)
        .pretendardFont(family: .Medium, size: 16)
        .foregroundStyle(.gray800)
        .lineLimit(1)

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
        memberTag("운영자")
      } else if member.id == store.currentMemberID {
        memberTag("나")
      } else if store.room.role == .owner, member.id != store.currentMemberID {
        Button { send(.removeTapped(member.id)) } label: {
          Image(systemName: "minus.circle.fill")
            .font(.system(size: 18))
            .foregroundStyle(.gray100)
        }
        .accessibilityLabel("\(member.name) 내보내기")
      }
    }
    .frame(minHeight: 24)
    .padding(.vertical, 16)
    .overlay(alignment: .bottom) { Rectangle().fill(.beige600).frame(height: 1) }
  }

  func memberAvatar(_ avatar: ClassMemberAvatar) -> some View {
    Image(asset: avatar.imageAsset)
      .resizable()
      .scaledToFit()
      .frame(width: 36, height: 36)
      .clipShape(Circle())
      .accessibilityHidden(true)
  }

  func memberTag(_ title: String) -> some View {
    Text(title)
      .pretendardFont(family: .SemiBold, size: 12)
      .foregroundStyle(.primary500)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
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
            .frame(minHeight: 31, alignment: .leading)
            .foregroundStyle(.gray800)
          Text("이 클래스에서만 보이는 이름이에요.")
            .pretendardFont(.bodyMedium)
            .frame(minHeight: 20, alignment: .leading)
            .foregroundStyle(.gray300)
        }

        TextField("이름을 입력해주세요", text: $store.draftName)
          .textInputAutocapitalization(.never)
          .pickeTextField(height: 44)

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
