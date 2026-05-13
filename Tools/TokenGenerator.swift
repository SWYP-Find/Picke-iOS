#!/usr/bin/env swift
//
//  TokenGenerator.swift
//  Reads Mode 1.tokens.json and emits Swift token files.
//  Run from repo root:  swift Tools/TokenGenerator.swift
//

import Foundation

// MARK: - Paths

let cwd = FileManager.default.currentDirectoryPath
let jsonURL = URL(fileURLWithPath: "\(cwd)/Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json")
let sourcesDir = "\(cwd)/Projects/Shared/DesignSystem/Sources"
let colorOut = "\(sourcesDir)/Color/ShapeStyle+.swift"
let cgfloatDir = "\(sourcesDir)/Extension/CGFloat"
let radiusOut = "\(cgfloatDir)/CGFloat+Radius+.swift"
let spacingOut = "\(cgfloatDir)/CGFloat+Spacing+.swift"
let componentOut = "\(sourcesDir)/UI/Token/ComponentToken.swift" // legacy nested file (deleted at end)
let componentNumberOut = "\(cgfloatDir)/CGFloat+Component+.swift"
try? FileManager.default.createDirectory(atPath: "\(sourcesDir)/UI/Token", withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: cgfloatDir, withIntermediateDirectories: true)

let data: Data
do {
  data = try Data(contentsOf: jsonURL)
} catch {
  fputs("[token-gen] cannot read JSON: \(jsonURL.path)\n", stderr)
  exit(1)
}

guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
  fputs("[token-gen] invalid JSON root\n", stderr); exit(1)
}

// MARK: - Helpers

func valueOf(_ any: Any) -> Any? {
  (any as? [String: Any])?["$value"]
}

func hexAlpha(_ value: Any) -> (hex: String, alpha: Double)? {
  guard let d = value as? [String: Any], let hex = d["hex"] as? String else { return nil }
  let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
  let a = (d["alpha"] as? Double) ?? 1.0
  return (raw.uppercased(), a)
}

func aliasToSwiftName(_ alias: String) -> String? {
  var s = alias
  if s.hasPrefix("{"), s.hasSuffix("}") { s = String(s.dropFirst().dropLast()) }
  let p = s.split(separator: ".").map(String.init)
  if p.count >= 4, p[0] == "Colors", p[1] == "brand" {
    if p.count == 5, p[3] == "Alpha" { return "\(p[2])Alpha\(p[4])" }
    return "\(p[2])\(p[3])"
  }
  if p.count >= 5, p[0] == "Colors", p[1] == "semantic", p[2] == "status" {
    let bucket = p[3].prefix(1).uppercased() + p[3].dropFirst()
    let leaf = p[4]
    return leaf == "Alpha" ? "status\(bucket)Alpha" : "status\(bucket)"
  }
  if p.count == 4, p[0] == "Colors", p[1] == "semantic" {
    let key = p[2]
    let prefix = (key == "background") ? "bg" : key
    return "\(prefix)\(capitalizeFirst(p[3]))"
  }
  return nil
}

// 'Primary200' → 'primary200' / 'BorderError' → 'borderError'
func lowerFirst(_ s: String) -> String {
  s.prefix(1).lowercased() + s.dropFirst()
}

let swiftKeywords: Set<String> = [
  "default", "case", "enum", "class", "struct", "var", "let", "func", "init",
  "private", "public", "internal", "fileprivate", "static", "extension", "protocol",
  "where", "as", "is", "self", "Self", "true", "false", "nil", "if", "else", "for", "in",
  "return", "switch", "break", "continue", "do", "try", "catch", "throw", "throws",
  "guard", "defer", "import", "typealias", "associatedtype",
]

func swiftKey(_ s: String) -> String {
  swiftKeywords.contains(s) ? "`\(s)`" : s
}

// hex→Swift 변수명 인덱스 (alpha=1 brand/semantic만). Component이 inline hex로 export 됐을 때 fallback 매칭용.
var hexIndex: [String: String] = [:]
var knownColorNames: Set<String> = []

func resolveComponentColor(_ node: [String: Any]) -> String? {
  if let str = node["$value"] as? String, let name = aliasToSwiftName(str) {
    return ".\(name)"
  }
  if let v = node["$value"] as? [String: Any], let hex = v["hex"] as? String {
    let raw = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let normalized = raw.uppercased()
    let alpha = (v["alpha"] as? Double) ?? 1.0
    // 1) aliasData.targetVariableName — 우리 토큰셋에 존재할 때만 사용
    if let exts = node["$extensions"] as? [String: Any],
       let alias = exts["com.figma.aliasData"] as? [String: Any],
       let target = alias["targetVariableName"] as? String, !target.isEmpty
    {
      let camel = lowerFirst(target)
      if knownColorNames.contains(camel) { return ".\(camel)" }
    }
    // 2) hex 매칭 — 같은 hex의 brand/semantic 변수가 있으면 그쪽으로 묶기
    if alpha >= 1.0, let matched = hexIndex[normalized] {
      return ".\(matched)"
    }
    // 3) fallback: inline hex
    return colorBody(hex: normalized, alpha: alpha)
  }
  return nil
}

func resolveComponentNumber(_ node: [String: Any]) -> String? {
  if let str = node["$value"] as? String {
    var s = str
    if s.hasPrefix("{"), s.hasSuffix("}") { s = String(s.dropFirst().dropLast()) }
    let p = s.split(separator: ".").map(String.init)
    if p.count == 2, p[0] == "Radius" { return ".\(swiftKey(p[1]))" }
  }
  if let n = node["$value"] as? Double { return formatNumber(n) }
  return nil
}

// Component subtree 를 flat path 로 풀어 ShapeStyle / CGFloat 확장에 직접 추가한다.
//   Component.button.primary.background.default → buttonPrimaryBackgroundDefault
//   Component.button.radius                     → buttonRadius
func walkComponentFlat(
  _ node: [String: Any],
  pathPrefix: [String],
  colorLines: inout [String],
  numberLines: inout [String]
) {
  let keys = node.keys.sorted()
  let leafKeys = keys.filter { (node[$0] as? [String: Any])?["$type"] != nil }
  let groupKeys = keys.filter { (node[$0] as? [String: Any])?["$type"] == nil }
  for key in leafKeys {
    guard let child = node[key] as? [String: Any], let type = child["$type"] as? String else { continue }
    let propName = flatPropertyName(pathPrefix + [key])
    switch type {
    case "color":
      if let expr = resolveComponentColor(child) {
        colorLines.append("  static var \(propName): Color { \(expr) }")
      }
    case "number":
      if let expr = resolveComponentNumber(child) {
        numberLines.append("  static let \(propName): CGFloat = \(expr)")
      }
    default: continue
    }
  }
  for key in groupKeys {
    guard let child = node[key] as? [String: Any] else { continue }
    walkComponentFlat(child, pathPrefix: pathPrefix + [key], colorLines: &colorLines, numberLines: &numberLines)
  }
}

// ["button", "primary", "background", "default"] → "buttonPrimaryBackgroundDefault"
func flatPropertyName(_ segs: [String]) -> String {
  guard let first = segs.first else { return "" }
  let head = first.prefix(1).lowercased() + first.dropFirst()
  let tail = segs.dropFirst().map(capitalizeFirst).joined()
  return swiftKey(head + tail)
}

func capitalizeFirst(_ s: String) -> String {
  s.prefix(1).uppercased() + s.dropFirst()
}

func formatNumber(_ d: Double) -> String {
  if d == d.rounded() { return "\(Int(d))" }
  let rounded = (d * 100).rounded() / 100
  return rounded == d.rounded() ? "\(Int(d))" : String(format: "%g", rounded)
}

func colorBody(hex: String, alpha: Double) -> String {
  alpha < 1 ? ".init(hex: \"\(hex)\", alpha: \(formatNumber(alpha)))" : ".init(hex: \"\(hex)\")"
}

func writeFile(_ path: String, _ contents: String) throws {
  try contents.write(toFile: path, atomically: true, encoding: .utf8)
  print("[token-gen] wrote \(path)")
}

let header = """
// AUTO-GENERATED by Tools/TokenGenerator.swift — DO NOT EDIT
// Source: Projects/Shared/DesignSystem/Resources/Mode 1.tokens.json
"""

// MARK: - Colors

let colors = json["Colors"] as! [String: Any]
let brand = colors["brand"] as! [String: Any]
let semantic = colors["semantic"] as! [String: Any]
let scales = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]
let brandGroups = ["primary", "secondary", "beige", "neutral"]

var lines: [String] = [header, "", "import SwiftUI", "", "public extension ShapeStyle where Self == Color {", ""]

// brand
for group in brandGroups {
  guard let g = brand[group] as? [String: Any] else { continue }
  lines.append("  // MARK: - Brand / \(capitalizeFirst(group))")
  for s in scales {
    if let node = g[s] as? [String: Any], let v = valueOf(node), let h = hexAlpha(v) {
      let name = "\(group)\(s)"
      lines.append("  static var \(name): Color { \(colorBody(hex: h.hex, alpha: h.alpha)) }")
      knownColorNames.insert(name)
      if h.alpha >= 1.0 { hexIndex[h.hex] = name }
    }
  }
  if let alpha = g["Alpha"] as? [String: Any] {
    for (k, v) in alpha.sorted(by: { $0.key < $1.key }) {
      if let node = v as? [String: Any], let val = valueOf(node), let h = hexAlpha(val) {
        let name = "\(group)Alpha\(k)"
        lines.append("  static var \(name): Color { \(colorBody(hex: h.hex, alpha: h.alpha)) }")
        knownColorNames.insert(name)
      }
    }
  }
  lines.append("")
}

// semantic prefixed groups
let semGroups: [(jsonKey: String, swiftPrefix: String)] = [
  ("text", "text"),
  ("border", "border"),
  ("surface", "surface"),
  ("background", "bg"),
]
for (key, prefix) in semGroups {
  guard let group = semantic[key] as? [String: Any] else { continue }
  lines.append("  // MARK: - Semantic / \(capitalizeFirst(key))")
  for (rawName, val) in group.sorted(by: { $0.key < $1.key }) {
    guard let node = val as? [String: Any], let v = valueOf(node) else { continue }
    let name = "\(prefix)\(capitalizeFirst(rawName))"
    if let h = hexAlpha(v) {
      lines.append("  static var \(name): Color { \(colorBody(hex: h.hex, alpha: h.alpha)) }")
      if h.alpha >= 1.0 { hexIndex[h.hex] = name }
    } else if let aliasStr = v as? String, let target = aliasToSwiftName(aliasStr) {
      lines.append("  static var \(name): Color { .\(target) }")
    }
    knownColorNames.insert(name)
  }
  lines.append("")
}

// status nested (status.error.error / status.error.Alpha / status.warning.warning / status.warning.Alpha)
if let status = semantic["status"] as? [String: Any] {
  lines.append("  // MARK: - Semantic / Status")
  for bucket in ["error", "warning"] {
    guard let b = status[bucket] as? [String: Any] else { continue }
    for (k, v) in b.sorted(by: { $0.key < $1.key }) {
      guard let node = v as? [String: Any], let val = valueOf(node), let h = hexAlpha(val) else { continue }
      let bucketCap = capitalizeFirst(bucket)
      let name = (k == "Alpha") ? "status\(bucketCap)Alpha" : "status\(bucketCap)"
      lines.append("  static var \(name): Color { \(colorBody(hex: h.hex, alpha: h.alpha)) }")
      knownColorNames.insert(name)
      if h.alpha >= 1.0 { hexIndex[h.hex] = name }
    }
  }
}

// Component colors — flat ShapeStyle 확장에 직접 합쳐 ComponentToken 중첩 enum 을 폐기.
let component = json["Component"] as! [String: Any]
var componentColorLines: [String] = []
var componentNumberLines: [String] = []
walkComponentFlat(component, pathPrefix: [], colorLines: &componentColorLines, numberLines: &componentNumberLines)
if !componentColorLines.isEmpty {
  lines.append("  // MARK: - Component")
  lines.append(contentsOf: componentColorLines)
  lines.append("")
}

lines.append("}")
lines.append("")
try writeFile(colorOut, lines.joined(separator: "\n"))

// MARK: - Radius

let radius = json["Radius"] as! [String: Any]
let radiusOrder = ["none", "default", "full"]
var rLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]
rLines.append("  // MARK: - Radius")
for k in radiusOrder {
  guard let node = radius[k] as? [String: Any], let v = valueOf(node), let n = v as? Double else { continue }
  let safe = (k == "default") ? "`default`" : k
  rLines.append("  static let \(safe): CGFloat = \(formatNumber(n))")
}

rLines.append("}")
rLines.append("")
try writeFile(radiusOut, rLines.joined(separator: "\n"))

// MARK: - Spacing

let spacing = json["Spacing"] as! [String: Any]
let spacingKeys = spacing.keys.compactMap(Int.init).sorted()
var sLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]
sLines.append("  // MARK: - Spacing")
for k in spacingKeys {
  guard let node = spacing[String(k)] as? [String: Any], let v = valueOf(node), let n = v as? Double else { continue }
  sLines.append("  static let s\(k): CGFloat = \(formatNumber(n))")
}

sLines.append("}")
sLines.append("")
try writeFile(spacingOut, sLines.joined(separator: "\n"))

// MARK: - Component (numbers)

// 색상은 위에서 ShapeStyle+.swift 에 이미 추가됨. 숫자만 CGFloat 확장으로 별도 출력.

if !componentNumberLines.isEmpty {
  var cLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]
  cLines.append("  // MARK: - Component")
  cLines.append(contentsOf: componentNumberLines)
  cLines.append("}")
  cLines.append("")
  try writeFile(componentNumberOut, cLines.joined(separator: "\n"))
}

// 옛 nested ComponentToken.swift 폐기: 더 이상 생성하지 않고 잔재 파일이 있으면 제거.
if FileManager.default.fileExists(atPath: componentOut) {
  try FileManager.default.removeItem(atPath: componentOut)
  print("[token-gen] removed legacy \(componentOut)")
}

print("[token-gen] done.")
