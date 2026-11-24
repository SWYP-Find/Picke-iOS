//
//  ClassDeadlineWheelColumn.swift
//  Class
//
//  Created by Picke on 10/15/26.
//

import PickeDesignKit
import SwiftUI

@available(iOS 18, *)
struct ClassDeadlineWheelColumn: View {
  let values: ClosedRange<Int>
  @Binding var selection: Int
  let label: String
  let text: (Int) -> String
  var cycleLength: Int?
  var onEditingChanged: (Bool) -> Void = { _ in }
  @State private var position: Int?
  @State private var isInteracting = false

  var body: some View {
    trackedScroll()
    .onAppear { synchronize() }
    .onChange(of: selection) { _, value in
      guard !isInteracting, position.map(normalized) != value else { return }
      synchronize()
      onEditingChanged(false)
    }
    .onDisappear {
      isInteracting = false
      onEditingChanged(false)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label)
    .accessibilityValue(text(position.map(normalized) ?? selection))
    .accessibilityIdentifier("class-deadline-wheel-\(label)")
    .accessibilityAdjustableAction { direction in
      let delta = direction == .increment ? 1 : -1
      selection = normalized(min(max(selection + delta, values.lowerBound), values.upperBound))
      synchronize()
    }
  }
}

@available(iOS 18, *)
private extension ClassDeadlineWheelColumn {
  @ViewBuilder
  func trackedScroll() -> some View {
    wheelScroll.onScrollPhaseChange { _, phase in
        switch phase {
        case .tracking, .interacting, .decelerating:
          isInteracting = true
          onEditingChanged(true)
        case .idle:
          if isInteracting { settle() }
        case .animating:
          break
        @unknown default:
          break
        }
    }
  }

  var wheelScroll: some View {
    ScrollView(.vertical) { rows() }
      .contentMargins(.vertical, 71, for: .scrollContent)
      .scrollIndicators(.hidden)
      .scrollTargetBehavior(.viewAligned)
      .scrollPosition(id: $position, anchor: .center)
      .frame(height: 174)
      .clipped()
      .mask(fadeMask)
  }

  func settle() {
    if let position, normalized(position) != selection {
      selection = normalized(position)
    }
    isInteracting = false
    synchronize()
    onEditingChanged(false)
  }

  func synchronize() {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) { position = selection }
  }

  @ViewBuilder
  func rows() -> some View {
    LazyVStack(spacing: 0) {
      ForEach(values, id: \.self) { value in
        Text(text(normalized(value)))
          .pretendardFont(family: .Regular, size: 22)
          .foregroundStyle(value == (position ?? selection) ? Color.black : Color.gray200)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .visualEffect { content, geometry in
            // Scroll-content coordinates exclude the71pt margins: its center is16pt.
            let distance = geometry.frame(in: .scrollView(axis: .vertical)).midY - 16
            let angle = distance / 87
            return content
              .scaleEffect(x: max(0.5, 1 - abs(distance) / 160), y: max(0.01, cos(angle)))
              .offset(y: 87 * sin(angle) - distance)
              .opacity(abs(angle) < .pi / 2 ? 1 : 0)
          }
          .id(value)
      }
    }
    .scrollTargetLayout()
  }

  var fadeMask: some View {
    LinearGradient(
      stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.22),
              .init(color: .black, location: 0.78), .init(color: .clear, location: 1)],
      startPoint: .top,
      endPoint: .bottom
    )
  }

  func normalized(_ value: Int) -> Int {
    guard let cycleLength else { return value }
    return (value % cycleLength + cycleLength) % cycleLength
  }
}
