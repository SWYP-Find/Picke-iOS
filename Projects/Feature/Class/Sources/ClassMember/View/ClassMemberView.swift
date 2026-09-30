import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: ClassMemberFeature.self)
public struct ClassMemberView: View {
  public let store: StoreOf<ClassMemberFeature>

  public init(store: StoreOf<ClassMemberFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "멤버 \(store.members.count)")
        .foregroundStyle(.gray500)

      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(store.members) { member in
            memberRow(member)
          }
        }
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .hidesSystemBars()
    .alert(
      "멤버를 삭제할까요?",
      isPresented: Binding(
        get: { store.selectedMember != nil },
        set: {
          if !$0 {
            send(.removeCancelled)
          }
        }
      )
    ) {
      Button("취소", role: .cancel) { send(.removeCancelled) }
      Button("삭제", role: .destructive) { send(.removeConfirmed) }
    } message: {
      Text("삭제한 멤버는 참여 코드를 통해 다시 입장할 수 있어요.")
    }
  }
}

private extension ClassMemberView {
  @ViewBuilder
  func memberRow(_ member: ClassMemberFeature.State.Member) -> some View {
    HStack(spacing: 12) {
      Text(member.name)
        .pretendardFont(.medium15)
        .foregroundStyle(.gray800)

      if member.isOwner {
        Text("선생님")
          .pretendardFont(.medium13)
          .foregroundStyle(.gray300)
      }

      Spacer(minLength: 0)

      if store.room.role == .owner, !member.isOwner {
        Button("삭제") { send(.removeTapped(member.id)) }
          .pretendardFont(.medium13)
          .foregroundStyle(.textError)
      }
    }
    .padding(.vertical, 16)
  }
}
