//
//  MainTabKeyboardObserver.swift
//  Picke
//
//  Created by Picke on 10/17/26.
//

import SwiftUI

/// Measures bottom occlusion even when the keyboard predates the tab shell.
struct MainTabKeyboardObserver: View {
  let onChange: (Bool) -> Void

  var body: some View {
    probes()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
      .onPreferenceChange(KeyboardInsetsPreference.self) { insets in
        guard let ignoring = insets.keyboardIgnoringBottom,
              let aware = insets.keyboardAwareBottom else { return }
        onChange(max(0, aware - ignoring) > 1)
      }
  }
}

extension MainTabKeyboardObserver {
  @ViewBuilder
  private func probes() -> some View {
    ZStack {
      GeometryReader { geometry in
        Color.clear.preference(
          key: KeyboardInsetsPreference.self,
          value: KeyboardInsets(keyboardAwareBottom: geometry.safeAreaInsets.bottom)
        )
      }
      GeometryReader { geometry in
        Color.clear.preference(
          key: KeyboardInsetsPreference.self,
          value: KeyboardInsets(keyboardIgnoringBottom: geometry.safeAreaInsets.bottom)
        )
      }
      .ignoresSafeArea(.keyboard, edges: .bottom)
    }
  }
}

private struct KeyboardInsets: Equatable {
  var keyboardAwareBottom: CGFloat?
  var keyboardIgnoringBottom: CGFloat?
}

private enum KeyboardInsetsPreference: PreferenceKey {
  static let defaultValue = KeyboardInsets()

  static func reduce(
    value: inout KeyboardInsets,
    nextValue: () -> KeyboardInsets
  ) {
    let next = nextValue()
    value.keyboardAwareBottom = next.keyboardAwareBottom ?? value.keyboardAwareBottom
    value.keyboardIgnoringBottom = next.keyboardIgnoringBottom ?? value.keyboardIgnoringBottom
  }
}
