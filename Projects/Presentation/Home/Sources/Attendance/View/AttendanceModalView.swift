//
//  AttendanceModalView.swift
//  Home
//

import SwiftUI

import ComposableArchitecture

@ViewAction(for: AttendanceModalFeature.self)
public struct AttendanceModalView: View {
  @Bindable public var store: StoreOf<AttendanceModalFeature>
  @GestureState private var dragOffset: CGFloat = 0

  public init(store: StoreOf<AttendanceModalFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      dimmedBackground()
      modalContent()
    }
  }
}

extension AttendanceModalView {
  @ViewBuilder
  private func dimmedBackground() -> some View {
    Color.black.opacity(0.4)
      .ignoresSafeArea()
      .contentShape(Rectangle())
      .onTapGesture { send(.dismissTapped) }
      .accessibilityLabel("출석 모달 닫기")
  }

  @ViewBuilder
  private func modalContent() -> some View {
    AttendanceSheetView(
      weekly: store.weekly,
      pointsEarned: store.pointsEarned
    )
    .offset(y: max(0, dragOffset))
    .gesture(dismissGesture())
  }

  private func dismissGesture() -> some Gesture {
    DragGesture(minimumDistance: 10)
      .updating($dragOffset) { value, offset, _ in
        offset = max(0, value.translation.height)
      }
      .onEnded { value in
        guard value.translation.height > 80 ||
          value.predictedEndTranslation.height > 140
        else {
          return
        }
        send(.dismissTapped)
      }
  }
}
