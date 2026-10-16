//
//  ClassMemberEditIcon.swift
//  Class
//
//  Created by Picke on 10/17/26.
//

import SwiftUI

struct ClassMemberEditIcon: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: 13.75, y: 2.5))
    path.addLine(to: CGPoint(x: 2.5, y: 13.75))
    path.addLine(to: CGPoint(x: 1.25, y: 18.75))
    path.addLine(to: CGPoint(x: 6.25, y: 17.5))
    path.addLine(to: CGPoint(x: 17.5, y: 6.25))
    path.addCurve(
      to: CGPoint(x: 13.75, y: 2.5),
      control1: CGPoint(x: 20, y: 3.75),
      control2: CGPoint(x: 16.25, y: 0)
    )
    path.closeSubpath()
    return path.applying(CGAffineTransform(scaleX: rect.width / 20, y: rect.height / 20))
  }
}
