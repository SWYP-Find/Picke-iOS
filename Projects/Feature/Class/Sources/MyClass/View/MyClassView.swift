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
    .onAppear { send(.onAppear) }
    .pickeModal(
      $store.scope(state: \.modal, action: \.modal),
      dimOpacity: 0.28
    ) { _ in
      if let roomID = store.selectedRoomID,
         let room = store.rooms.first(where: { $0.id == roomID })
      {
        ZStack(alignment: .bottom) {
          Color.clear
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { send(.managementDismissed) }
          ClassManagementSheet(
            room: room,
            onEdit: { send(.editClassTapped) },
            onDelete: { send(.deleteTapped) }
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
    .customAlert($store.scope(state: \.customAlert, action: \.customAlert))
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
    switch store.viewState {
    case .error:
      PickeRetryErrorView(message: "클래스를 불러오지 못했어요") { send(.retryTapped) }
        .frame(maxWidth: .infinity, minHeight: 160)
    case .loading:
      MyClassSkeletonView()
    case .empty:
      Text("아직 클래스가 없어요")
        .pretendardFont(.medium15)
        .foregroundStyle(.gray300)
        .frame(maxWidth: .infinity, minHeight: 160)
    case let .loaded(rooms):
      LazyVStack(spacing: 12) {
        ForEach(rooms) { room in
          MyClassRoomCard(
            room: room,
            onOpen: { send(.roomTapped(room.id)) },
            onManage: { send(.managementTapped(room.id)) }
          )
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
