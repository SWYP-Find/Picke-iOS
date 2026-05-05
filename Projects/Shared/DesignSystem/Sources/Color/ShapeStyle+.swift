//
//  ShapeStyle+.swift
//  DesignSystem
//
//  Picke Figma color tokens (primary / secondary / gray / beige, 50~900).
//

import SwiftUI

public extension ShapeStyle where Self == Color {
  // Primary
  static var primary50: Color { .init(hex: "F3EBE9") }
  static var primary100: Color { .init(hex: "E7D7D3") }
  static var primary200: Color { .init(hex: "D0AFA8") }
  static var primary300: Color { .init(hex: "B8887C") }
  static var primary400: Color { .init(hex: "A16051") }
  static var primary500: Color { .init(hex: "893825") }
  static var primary600: Color { .init(hex: "7A3626") }
  static var primary700: Color { .init(hex: "71372A") }
  static var primary800: Color { .init(hex: "653226") }
  static var primary900: Color { .init(hex: "4E2A21") }

  // Secondary
  static var secondary50: Color { .init(hex: "FCF8F1") }
  static var secondary100: Color { .init(hex: "F9F1E3") }
  static var secondary200: Color { .init(hex: "F3E3C7") }
  static var secondary300: Color { .init(hex: "EDD5AC") }
  static var secondary400: Color { .init(hex: "E7C790") }
  static var secondary500: Color { .init(hex: "E1B974") }
  static var secondary600: Color { .init(hex: "CEA969") }
  static var secondary700: Color { .init(hex: "B7965C") }
  static var secondary800: Color { .init(hex: "A38653") }
  static var secondary900: Color { .init(hex: "92784A") }

  // Gray
  static var gray50: Color { .init(hex: "EBEBEB") }
  static var gray100: Color { .init(hex: "D7D7D7") }
  static var gray200: Color { .init(hex: "B0AFAE") }
  static var gray300: Color { .init(hex: "888786") }
  static var gray400: Color { .init(hex: "615F5D") }
  static var gray500: Color { .init(hex: "393735") }
  static var gray600: Color { .init(hex: "2B2A28") }
  static var gray700: Color { .init(hex: "222120") }
  static var gray800: Color { .init(hex: "1A1918") }
  static var gray900: Color { .init(hex: "131212") }

  // Beige
  static var beige50: Color { .init(hex: "FEFEFD") }
  static var beige100: Color { .init(hex: "FDFCFB") }
  static var beige200: Color { .init(hex: "FBF9F7") }
  static var beige300: Color { .init(hex: "F9F7F2") }
  static var beige400: Color { .init(hex: "F7F4EE") }
  static var beige500: Color { .init(hex: "F5F1EA") }
  static var beige600: Color { .init(hex: "EFEAE0") }
  static var beige700: Color { .init(hex: "DAD1BF") }
  static var beige800: Color { .init(hex: "CEC1A8") }
  static var beige900: Color { .init(hex: "B7A88B") }
}
