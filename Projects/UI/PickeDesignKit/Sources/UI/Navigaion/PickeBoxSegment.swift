//
//  PickeBoxSegment.swift
//  PickeDesignKit
//

import SwiftUI

/// 회색 트랙 위에서 한 칸이 beige 카드로 떠오르는 박스형 세그먼트.
public struct PickeBoxSegment<Item: Hashable>: View {
  private let items: [Item]
  @Binding private var selection: Item
  private let title: (Item) -> String

  public init(
    _ items: [Item],
    selection: Binding<Item>,
    title: @escaping (Item) -> String
  ) {
    self.items = items
    self._selection = selection
    self.title = title
  }

  public var body: some View {
    HStack(spacing: 0) {
      ForEach(items, id: \.self) { item in
        segment(item)
      }
    }
    .padding(4)
    .roundedBackground(.gray50)
  }
}

private extension PickeBoxSegment {
  @ViewBuilder
  func segment(_ item: Item) -> some View {
    let isSelected = selection == item
    Button {
      selection = item
    } label: {
      Text(title(item))
        .pretendardFont(isSelected ? .headingSmall : .bodyMedium)
        .foregroundStyle(isSelected ? .primary500 : .gray300)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background {
          if isSelected {
            RoundedRectangle(cornerRadius: .radiusDefault)
              .fill(.beige50)
          }
        }
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
