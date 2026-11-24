//
//  ClassAIInsightHeading.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import PickeDesignKit
import SwiftUI

struct ClassAIInsightHeading: View {
  let title: String
  var titleFont: CustomSizeFont = .semiBold15
  var titleLineHeight: CGFloat? = nil
  var iconSize: CGFloat = 24
  var spacing: CGFloat = 8

  var body: some View {
    HStack(spacing: spacing) {
      Image(systemName: "sparkle")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.beige50)
        .frame(width: iconSize, height: iconSize)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 6))
      Text(title)
        .pretendardFont(titleFont)
        .frame(minHeight: titleLineHeight)
    }
  }
}
