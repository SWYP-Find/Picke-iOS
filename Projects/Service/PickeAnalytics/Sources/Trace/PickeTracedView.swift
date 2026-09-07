//
//  PickeTracedView.swift
//  PickeAnalytics
//

import SwiftUI

import SentrySwiftUI

/// 화면 렌더 구간을 Sentry 트랜잭션으로 감싸는 래퍼.
///
/// SentrySwiftUI 를 여기서만 링크해 앱·피처는 관측 SDK 를 모르게 둔다.
public struct PickeTracedView<Content: View>: View {
  private let name: String
  private let content: () -> Content

  public init(_ name: String, @ViewBuilder content: @escaping () -> Content) {
    self.name = name
    self.content = content
  }

  public var body: some View {
    SentryTracedView(name) {
      content()
    }
  }
}
