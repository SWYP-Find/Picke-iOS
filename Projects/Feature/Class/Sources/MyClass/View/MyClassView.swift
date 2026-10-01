import ClassDomainInterface
import ComposableArchitecture
import PickeDesignKit
import PickeSharedUI
import SwiftUI

@ViewAction(for: MyClassFeature.self)
public struct MyClassView: View {
  @Bindable public var store: StoreOf<MyClassFeature>

  public init(store: StoreOf<MyClassFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      PickeNavigationBar(onBack: { send(.backTapped) }, centerTitle: "내 클래스")
        .foregroundStyle(.gray500)

      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          progressChips()
          roomList()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
      }
      .scrollIndicators(.hidden)
    }
    .screenBackground()
    .toolbar(.hidden, for: .navigationBar)
    .toolbar(.visible, for: .tabBar)
    .onAppear { send(.onAppear) }
  }
}

private extension MyClassView {
  @ViewBuilder
  func progressChips() -> some View {
    HStack(spacing: 8) {
      ForEach(MyClassFeature.State.Progress.allCases, id: \.self) { progress in
        Button { send(.progressTapped(progress)) } label: {
          Text(progress.title)
            .pickeSortChip(isSelected: store.progress == progress)
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  func roomList() -> some View {
    if store.shouldShowLoadError {
      PickeRetryErrorView(message: "클래스를 불러오지 못했어요") { send(.retryTapped) }
        .frame(maxWidth: .infinity, minHeight: 160)
    } else if store.shouldShowSkeleton {
      MyClassSkeletonView()
    } else if store.visibleRooms.isEmpty {
      Text("아직 클래스가 없어요")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .frame(maxWidth: .infinity, minHeight: 160)
    } else {
      LazyVStack(spacing: 12) {
        ForEach(store.visibleRooms) { room in
          Button { send(.roomTapped(room.id)) } label: {
            MyClassRoomCard(room: room)
          }
          .buttonStyle(.plain)
        }
      }
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
