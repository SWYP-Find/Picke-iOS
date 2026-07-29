//
//  BottomActionSheet.swift
//  DesignSystem
//

import SwiftUI

public struct BottomActionItem: Identifiable {
  public let id = UUID()
  public let title: String
  public let systemImage: String
  public let isDestructive: Bool
  public let action: () -> Void

  public init(
    title: String,
    systemImage: String,
    isDestructive: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.isDestructive = isDestructive
    self.action = action
  }
}

public struct BottomActionSheet: View {
  private let items: [BottomActionItem]
  private let onDismiss: () -> Void

  public init(
    items: [BottomActionItem],
    onDismiss: @escaping () -> Void
  ) {
    self.items = items
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .onTapGesture { onDismiss() }

      VStack(spacing: 8) {
        ForEach(items) { item in
          Button {
            onDismiss()
            item.action()
          } label: {
            HStack(spacing: 4) {
              Image(systemName: item.systemImage)
                .font(.system(size: 14, weight: .medium))
              Text(item.title)
                .pretendardFont(.medium13)
            }
            .foregroundStyle(.beige50)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(.primary500, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.bottom, 28)
    }
    .transition(.opacity)
  }
}
