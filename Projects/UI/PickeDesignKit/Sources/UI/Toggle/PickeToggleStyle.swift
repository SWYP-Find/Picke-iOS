//
//  PickeToggleStyle.swift
//  PickeDesignKit
//

import SwiftUI

/// 32x18 스위치. `Toggle(...).toggleStyle(.picke)` 로 쓴다.
public struct PickeToggleStyle: ToggleStyle {
  public func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 16) {
      configuration.label
      Spacer(minLength: 0)
      Capsule()
        .fill(configuration.isOn ? .toggleTrackOn : .toggleTrackOff)
        .frame(width: 32, height: 18)
        .overlay(alignment: configuration.isOn ? .trailing : .leading) {
          Circle()
            .fill(.toggleThumbDefault)
            .frame(width: 14, height: 14)
            .padding(2)
        }
        .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
        .onTapGesture { configuration.isOn.toggle() }
    }
  }
}

public extension ToggleStyle where Self == PickeToggleStyle {
  static var picke: PickeToggleStyle {
    .init()
  }
}
