//
//  RecapScoreBar.swift
//  Profile
//

import SwiftUI

import PickeDesignKit
import Entity

public struct RecapScoreBar: View {
  private let axis: RecapScoreAxis
  private let trackWidth: CGFloat = 48

  @State private var progress: CGFloat = 0

  public init(axis: RecapScoreAxis) {
    self.axis = axis
  }

  public var body: some View {
    HStack(spacing: 8) {
      Text(axis.label)
        .pretendardFont(.medium10)
        .foregroundStyle(.neutral900)
        .fixedSize()

      Spacer(minLength: 4)

      ZStack(alignment: .leading) {
        Capsule()
          .fill(.primary100)
          .frame(width: trackWidth, height: 4)
        Capsule()
          .fill(.primary500)
          .frame(width: trackWidth * ratio * progress, height: 4)
      }
      .frame(width: trackWidth)

      Text("\(Int(axis.value.rounded()))")
        .pretendardFont(.semiBold11)
        .foregroundStyle(.neutral900)
        .fixedSize()
        .frame(minWidth: 18, alignment: .trailing)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity)
    .roundedBackground(.beige400)
    .onAppear {
      progress = 0
      withAnimation(.easeOut(duration: 0.7)) { progress = 1 }
    }
  }

  private var ratio: CGFloat {
    max(0, min(1, axis.value / 100))
  }
}
