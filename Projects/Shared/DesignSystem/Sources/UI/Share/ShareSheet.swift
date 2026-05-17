//
//  ShareSheet.swift
//  DesignSystem
//
//  애플 기본 공유 시트 (UIActivityViewController) 를 SwiftUI `.sheet` 로 띄우기 위한 wrapper.
//

import SwiftUI
import UIKit

public struct ShareSheet: UIViewControllerRepresentable {
  private let items: [Any]

  public init(items: [Any]) {
    self.items = items
  }

  public func makeUIViewController(context _: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  public func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
