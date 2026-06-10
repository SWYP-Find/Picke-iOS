//
//  PickeNavigationBar.swift
//  DesignSystem
//
//  Picke 공통 네비게이션 바 — 좌측 back / 가운데 옵션 / 우측 ViewBuilder.
//

import SwiftUI

/// 화면 상단에 공통으로 올라가는 네비게이션 바.
/// - `onBack` 이 nil 이면 좌측 영역은 24×24 placeholder 만 남는다.
/// - `centerIcon` 이 nil 이면 가운데는 빈 공간.
/// - 우측은 호출처에서 자유롭게 ViewBuilder 로 주입.
///
/// 색상은 호출처에서 `.foregroundStyle(.beige50)` 같은 modifier 로 위임.
public struct PickeNavigationBar<Trailing: View>: View {
  private let onBack: (() -> Void)?
  private let centerIcon: Image?
  private let centerTitle: String?
  private let trailing: () -> Trailing

  public init(
    onBack: (() -> Void)? = nil,
    centerIcon: Image? = nil,
    centerTitle: String? = nil,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) {
    self.onBack = onBack
    self.centerIcon = centerIcon
    self.centerTitle = centerTitle
    self.trailing = trailing
  }

  public var body: some View {
    HStack {
      leadingArea
      Spacer()
      centerArea
      Spacer()
      trailing()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var leadingArea: some View {
    if let onBack {
      Button { onBack() } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .semibold))
          .frame(width: 24, height: 24)
      }
      .buttonStyle(.plain)
    } else {
      Color.clear.frame(width: 24, height: 24)
    }
  }

  @ViewBuilder
  private var centerArea: some View {
    if let centerTitle {
      Text(centerTitle)
        .pretendardFont(family: .SemiBold, size: 16)
        .kerning(-0.4)
    } else if let centerIcon {
      centerIcon
        .font(.system(size: 16, weight: .semibold))
        .frame(width: 24, height: 24)
    } else {
      EmptyView()
    }
  }
}

public extension PickeNavigationBar where Trailing == EmptyView {
  init(
    onBack: (() -> Void)? = nil,
    centerIcon: Image? = nil,
    centerTitle: String? = nil
  ) {
    self.init(onBack: onBack, centerIcon: centerIcon, centerTitle: centerTitle) { EmptyView() }
  }
}
