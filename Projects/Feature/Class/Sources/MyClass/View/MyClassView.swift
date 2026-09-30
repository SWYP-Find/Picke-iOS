import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import SwiftUI

@ViewAction(for: MyClassFeature.self)
public struct MyClassView: View {
  public let store: StoreOf<MyClassFeature>

  public init(store: StoreOf<MyClassFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "내 클래스")
        .foregroundStyle(.gray500)

      ownershipTabs()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          progressChips()
          roomList()
        }
        .padding(16)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .hidesSystemBars()
    .onAppear { send(.onAppear) }
  }
}

private extension MyClassView {
  @ViewBuilder
  func ownershipTabs() -> some View {
    HStack(spacing: 0) {
      ForEach(MyClassFeature.State.Ownership.allCases, id: \.self) { ownership in
        Button { send(.ownershipTapped(ownership)) } label: {
          Text(ownership.title)
            .pretendardFont(.semiBold15)
            .foregroundStyle(store.ownership == ownership ? .gray800 : .gray300)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .overlay(alignment: .bottom) {
              if store.ownership == ownership {
                Rectangle()
                  .fill(.gray800)
                  .frame(height: 2)
              }
            }
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  func progressChips() -> some View {
    HStack(spacing: 8) {
      ForEach(MyClassFeature.State.Progress.allCases, id: \.self) { progress in
        Button { send(.progressTapped(progress)) } label: {
          Text(progress.title)
            .pickeChoiceChip(isSelected: store.progress == progress)
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  func roomList() -> some View {
    if store.isLoading {
      ProgressView()
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if let message = store.errorMessage {
      Text(message)
        .pretendardFont(.medium15)
        .foregroundStyle(.textError)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if store.visibleRooms.isEmpty {
      Text("아직 클래스가 없어요")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else {
      LazyVStack(spacing: 12) {
        ForEach(store.visibleRooms) { room in
          Button { send(.roomTapped(room.id)) } label: {
            roomCard(room)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @ViewBuilder
  func roomCard(_ room: ClassRoom) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        Text(room.role == .owner ? "내가 만든 클래스" : "참여한 클래스")
          .pretendardFont(.medium13)
          .foregroundStyle(.gray300)
        Spacer(minLength: 0)
        Text(room.status == .open ? "진행 중" : "종료")
          .pretendardFont(.medium13)
          .foregroundStyle(.gray500)
      }

      Text(room.name)
        .pretendardFont(.bold18)
        .foregroundStyle(.gray800)

      Text(room.battle.title)
        .pretendardFont(.medium15)
        .foregroundStyle(.gray500)
        .lineLimit(2)

      Text("멤버 \(room.memberCount)명")
        .pretendardFont(.medium13)
        .foregroundStyle(.gray300)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white, in: RoundedRectangle(cornerRadius: 12))
  }
}

private extension MyClassFeature.State.Ownership {
  var title: String {
    switch self {
    case .all: "전체"
    case .created: "내가 만든 클래스"
    case .joined: "참여한 클래스"
    }
  }
}

private extension MyClassFeature.State.Progress {
  var title: String {
    switch self {
    case .all: "전체"
    case .open: "진행 중"
    case .closed: "종료"
    }
  }
}
