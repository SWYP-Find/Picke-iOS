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

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkle")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.beige50)
        .frame(width: 24, height: 24)
        .background(.primary500, in: RoundedRectangle(cornerRadius: 6))
      Text(title)
        .pretendardFont(.semiBold15)
    }
  }
}
