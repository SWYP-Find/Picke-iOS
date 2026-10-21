//
//  PickeNavigationBar.swift
//  PickeDesignKit
//
//  Created by Picke on 10/11/26.
//

import SwiftUI

/// 화면 상단에 공통으로 올라가는 네비게이션 바.
/// 기본 타이틀은 바 전체 기준 중앙에 놓이고, `leadingTitle`은 뒤로가기 버튼 옆에 놓인다.
/// 두 타이틀을 함께 전달하면 `leadingTitle`이 우선한다.
/// 색상은 호출처에서 `.foregroundStyle(.beige50)` 같은 modifier 로 위임.
public struct PickeNavigationBar<Trailing: View>: View {
  private let onBack: (() -> Void)?
  private let centerIcon: Image?
  private let centerTitle: String?
  private let leadingTitle: String?
  private let trailing: () -> Trailing

  public init(
    onBack: (() -> Void)? = nil,
    centerIcon: Image? = nil,
    centerTitle: String? = nil,
    leadingTitle: String? = nil,
    @ViewBuilder trailing: @escaping () -> Trailing
  ) {
    self.onBack = onBack
    self.centerIcon = centerIcon
    self.centerTitle = centerTitle
    self.leadingTitle = leadingTitle
    self.trailing = trailing
  }

  public var body: some View {
    ZStack {
      centerArea

      HStack(spacing: 4) {
        leadingArea
        if let leadingTitle {
          Text(leadingTitle)
            .pretendardFont(.headingMedium)
            .kerning(-0.4)
            .lineLimit(1)
        }
        Spacer()
        trailing()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  @ViewBuilder
  private var leadingArea: some View {
    if let onBack {
      Button { onBack() } label: {
        Path { path in
          path.move(to: CGPoint(x: 17, y: 2))
          path.addLine(to: CGPoint(x: 7, y: 12))
          path.addLine(to: CGPoint(x: 17, y: 22))
        }
          .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .butt, lineJoin: .miter))
          .frame(width: 24, height: 24)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("뒤로")
      .accessibilityIdentifier("chevron.left")
    } else {
      Color.clear.frame(width: 24, height: 24)
    }
  }

  @ViewBuilder
  private var centerArea: some View {
    if leadingTitle == nil, let centerTitle {
      Text(centerTitle)
        .pretendardFont(.headingMedium)
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
    centerTitle: String? = nil,
    leadingTitle: String? = nil
  ) {
    self.init(
      onBack: onBack,
      centerIcon: centerIcon,
      centerTitle: centerTitle,
      leadingTitle: leadingTitle
    ) { EmptyView() }
  }
}
