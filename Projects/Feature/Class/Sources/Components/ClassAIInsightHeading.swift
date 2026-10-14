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
  var isCompact: Bool = false

  var body: some View {
    HStack(spacing: isCompact ? 6 : 8) {
      Image(systemName: "sparkle")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.beige50)
        .frame(width: isCompact ? 20 : 24, height: isCompact ? 20 : 24)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 6))
      Text(title)
        .pretendardFont(isCompact ? .bold11 : .semiBold15)
        .frame(minHeight: isCompact ? 15.4 : nil)
    }
  }
}
