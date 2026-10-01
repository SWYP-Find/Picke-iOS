//
//  PickeBoxSegment.swift
//  PickeDesignKit
//

import SwiftUI

public extension View {
  /// 박스형 세그먼트의 한 칸. 선택 시 beige50 박스 + primary500 텍스트.
  /// `namespace` 를 넘기면 선택 박스가 칸 사이를 미끄러지듯 이동한다.
  func pickeBoxSegment(
    isSelected: Bool,
    namespace: Namespace.ID? = nil
  ) -> some View {
    pretendardFont(isSelected ? .headingSmall : .bodyMedium)
      .foregroundStyle(isSelected ? .primary500 : .gray300)
      .frame(maxWidth: .infinity)
      .frame(height: 36)
      .background {
        if isSelected {
          if let namespace {
            RoundedRectangle(cornerRadius: .radiusDefault)
              .fill(.beige50)
              .matchedGeometryEffect(id: "pickeBoxSegment", in: namespace)
          } else {
            RoundedRectangle(cornerRadius: .radiusDefault)
              .fill(.beige50)
          }
        }
      }
      .contentShape(Rectangle())
  }

  /// 박스형 세그먼트 칸들을 감싸는 gray50 트랙.
  func pickeBoxSegmentTrack() -> some View {
    padding(4)
      .roundedBackground(.gray50)
  }
}
