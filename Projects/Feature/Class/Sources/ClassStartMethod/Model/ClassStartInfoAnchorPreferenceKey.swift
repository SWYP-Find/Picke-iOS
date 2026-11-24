//
//  ClassStartInfoAnchorPreferenceKey.swift
//  Class
//
//  Created by Picke on 10/12/26.
//

import SwiftUI

struct ClassStartInfoAnchorPreferenceKey: PreferenceKey {
  static var defaultValue: [ClassStartGuideKind: Anchor<CGRect>] = [:]

  static func reduce(
    value: inout [ClassStartGuideKind: Anchor<CGRect>],
    nextValue: () -> [ClassStartGuideKind: Anchor<CGRect>]
  ) {
    value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
  }
}
