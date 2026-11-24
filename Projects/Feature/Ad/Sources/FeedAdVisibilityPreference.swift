//
//  FeedAdVisibilityPreference.swift
//  Ad
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

struct FeedAdVisibilityPreference: PreferenceKey {
  static let defaultValue = false

  static func reduce(
    value: inout Bool,
    nextValue: () -> Bool
  ) {
    value = value || nextValue()
  }
}
