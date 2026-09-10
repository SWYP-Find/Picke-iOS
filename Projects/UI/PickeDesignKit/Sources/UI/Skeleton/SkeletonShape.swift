//
//  SkeletonShape.swift
//  PickeDesignKit
//

import SwiftUI

/// 스켈레톤 자리표시자의 외곽 형태.
public enum SkeletonShape: Shape {
  case rect
  case round(cornerRadius: CGFloat = .radiusDefault)
  case circle

  public func path(in rect: CGRect) -> Path {
    switch self {
    case .rect:
      Rectangle().path(in: rect)

    case let .round(cornerRadius):
      RoundedRectangle(cornerRadius: cornerRadius, style: .circular).path(in: rect)

    case .circle:
      Circle().path(in: rect)
    }
  }
}
