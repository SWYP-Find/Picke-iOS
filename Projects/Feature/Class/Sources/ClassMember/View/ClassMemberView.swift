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
          Text("멤버 \(store.members.count)")
            .pretendardFont(family: .Medium, size: 14)
            .foregroundStyle(.gray300)
            .padding(.bottom, 4)

          ForEach(store.visibleMembers) { member in
            memberRow(member)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.hidden, for: .tabBar)
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
  }
}

private extension ClassMemberView {
  var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 18))
        .foregroundStyle(.gray300)
      TextField("이름을 입력해 주세요.", text: $store.searchText)
        .pretendardFont(.medium15)
        .foregroundStyle(.gray800)
    }
    .padding(.horizontal, 12)
    .frame(height: 44)
    .background(.beige50, in: RoundedRectangle(cornerRadius: 2))
    .overlay(RoundedRectangle(cornerRadius: 2).stroke(.beige600, lineWidth: 1))
  }

  @ViewBuilder
  func memberRow(_ member: ClassMemberFeature.State.Member) -> some View {
    HStack(spacing: 12) {
      PickeAvatarView(imageURL: nil, fallback: member.name, size: 36)

      Text(member.name)
        .pretendardFont(family: .Medium, size: 16)
        .foregroundStyle(.gray800)

      Spacer(minLength: 0)

      if member.isOwner {
        Text("운영자")
          .pretendardFont(family: .SemiBold, size: 12)
          .foregroundStyle(.primary500)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.beige600, in: RoundedRectangle(cornerRadius: 2))
      } else if store.room.role == .owner {
        Button { send(.removeTapped(member.id)) } label: {
          Image(systemName: "minus.circle")
            .font(.system(size: 20))
            .foregroundStyle(.gray500)
            .frame(width: 32, height: 32)
        }
        .accessibilityLabel("\(member.name) 내보내기")
      }
    }
    .frame(height: 68)
    .overlay(alignment: .bottom) { Rectangle().fill(.beige600).frame(height: 1) }
  }
}
