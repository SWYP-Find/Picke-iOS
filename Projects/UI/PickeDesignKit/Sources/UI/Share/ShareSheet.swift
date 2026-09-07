//
//  ShareSheet.swift
//  PickeDesignKit
//

import SwiftUI
import UIKit

/// 시스템 공유 시트.
///
/// SwiftUIX 의 `AppActivityView` 에서 완료 콜백과 제외 액티비티 옵션만 옮겨 왔다.
/// 라이브러리 전체를 의존성으로 들이는 대신 필요한 조각만 가져온다. (SwiftUIX, MIT License)
public struct ShareSheet: UIViewControllerRepresentable {
  private let items: [Any]
  private let excludedActivityTypes: [UIActivity.ActivityType]
  private let onComplete: ((Bool) -> Void)?

  public init(
    items: [Any],
    excludedActivityTypes: [UIActivity.ActivityType] = [],
    onComplete: ((Bool) -> Void)? = nil
  ) {
    self.items = items
    self.excludedActivityTypes = excludedActivityTypes
    self.onComplete = onComplete
  }

  public func makeUIViewController(context _: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    controller.excludedActivityTypes = excludedActivityTypes.isEmpty ? nil : excludedActivityTypes
    controller.completionWithItemsHandler = { _, completed, _, _ in
      onComplete?(completed)
    }
    return controller
  }

  public func updateUIViewController(
    _: UIActivityViewController,
    context _: Context
  ) {}
}
