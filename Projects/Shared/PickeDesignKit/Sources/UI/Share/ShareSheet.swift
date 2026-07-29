//
//  ShareSheet.swift
//  DesignSystem
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

  public func updateUIViewController(
    _: UIActivityViewController,
    context _: Context
  ) {}
}
