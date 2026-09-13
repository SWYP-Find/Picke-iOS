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
