//
//  PickeMoreMenuItem.swift
//  PickeSharedUI
//
//  Created by Picke on 11/10/26.
//

import PickeDesignKit

/// Android `PickeMoreMenuItem` — "…" 메뉴 한 칸(아이콘 + 글자 + 동작).
public struct PickeMoreMenuItem: Identifiable {
  public let title: String
  public let icon: ImageAsset
  public let action: () -> Void

  public var id: String { title }

  public init(
    title: String,
    icon: ImageAsset,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.icon = icon
    self.action = action
  }

  /// Android `comment_menu_delete` + `ic_trash`.
  public static func delete(_ action: @escaping () -> Void) -> PickeMoreMenuItem {
    PickeMoreMenuItem(title: "삭제", icon: .trash, action: action)
  }

  /// Android `comment_menu_edit` + `ic_edit`.
  public static func edit(_ action: @escaping () -> Void) -> PickeMoreMenuItem {
    PickeMoreMenuItem(title: "수정", icon: .edit, action: action)
  }

  /// Android `comment_menu_report` + `ic_bell`.
  public static func report(_ action: @escaping () -> Void) -> PickeMoreMenuItem {
    PickeMoreMenuItem(title: "신고", icon: .report, action: action)
  }
}
