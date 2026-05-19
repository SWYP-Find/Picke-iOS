#!/usr/bin/env swift
//
//  TokenGenerator.swift
//  Reads Tokens Studio JSON (primitive/semantic/component) from the SWYP-Find/design-tokens
//  repo and emits Swift token files. Source resolution order:
//    1. $TOKENS_SOURCE_DIR  (CI / explicit override)
//    2. ../design-tokens    (local layout: sibling checkout)
//  Run from Picke-iOS repo root:  swift Tools/TokenGenerator.swift
//

import Foundation

// MARK: - Source resolution

let env = ProcessInfo.processInfo.environment
let cwd = FileManager.default.currentDirectoryPath

func resolveSourceDir() -> String {
  if let override = env["TOKENS_SOURCE_DIR"], !override.isEmpty {
    return override
  }
  let sibling = URL(fileURLWithPath: cwd).deletingLastPathComponent()
    .appendingPathComponent("design-tokens").path
  return sibling
}

let sourceDir = resolveSourceDir()
let primitiveURL = URL(fileURLWithPath: "\(sourceDir)/primitive.json")
let semanticURL = URL(fileURLWithPath: "\(sourceDir)/semantic.json")
let componentURL = URL(fileURLWithPath: "\(sourceDir)/component.json")

for url in [primitiveURL, semanticURL, componentURL] {
  guard FileManager.default.fileExists(atPath: url.path) else {
    fputs("""
    [token-gen] cannot find \(url.lastPathComponent) at: \(url.path)
    Set TOKENS_SOURCE_DIR to your design-tokens checkout, e.g.
      TOKENS_SOURCE_DIR=../design-tokens swift Tools/TokenGenerator.swift
    Or clone SWYP-Find/design-tokens as a sibling of this repo.

    """, stderr)
    exit(1)
  }
}

// MARK: - Output paths

let sourcesDir = "\(cwd)/Projects/Shared/DesignSystem/Sources"
let colorOut = "\(sourcesDir)/Color/ShapeStyle+.swift"
let cgfloatDir = "\(sourcesDir)/Extension/CGFloat"
let radiusOut = "\(cgfloatDir)/CGFloat+Radius+.swift"
let spacingOut = "\(cgfloatDir)/CGFloat+Spacing+.swift"
let componentNumberOut = "\(cgfloatDir)/CGFloat+Component+.swift"
let componentTokenOut = "\(sourcesDir)/UI/Token/ComponentToken.swift"

try? FileManager.default.createDirectory(atPath: "\(sourcesDir)/UI/Token", withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: cgfloatDir, withIntermediateDirectories: true)

// MARK: - Loading

func loadJSON(_ url: URL) -> [String: Any] {
  guard let data = try? Data(contentsOf: url),
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  else {
    fputs("[token-gen] cannot read \(url.path)\n", stderr)
    exit(1)
  }
  return obj
}

let primitive = loadJSON(primitiveURL)
let semantic = loadJSON(semanticURL)
let component = loadJSON(componentURL)

// MARK: - Registry & reference resolution

typealias TokenNode = [String: Any]
typealias Registry = [String: TokenNode]

/// Flattens a token tree by dotted path. Leaves are `{$type, $value, ...}` dicts.
func flatten(_ tree: [String: Any], path: [String], into registry: inout Registry) {
  for (key, value) in tree {
    guard let dict = value as? [String: Any] else { continue }
    let newPath = path + [key]
    if dict["$type"] != nil, dict["$value"] != nil {
      registry[newPath.joined(separator: ".")] = dict
    } else {
      flatten(dict, path: newPath, into: &registry)
    }
  }
}

var registry: Registry = [:]
flatten(primitive, path: [], into: &registry)
flatten(semantic, path: [], into: &registry)
flatten(component, path: [], into: &registry)

/// `"{primary.500}"` → `"primary.500"`. Nil for non-references.
func referencePath(_ s: String) -> String? {
  guard s.hasPrefix("{"), s.hasSuffix("}") else { return nil }
  return String(s.dropFirst().dropLast())
}

/// Recursively resolves a `$value`, following `{...}` references until a literal is reached.
/// Returns nil only on cycle.
func resolveValue(_ value: Any, visited: Set<String> = []) -> Any? {
  if let s = value as? String, let ref = referencePath(s) {
    if visited.contains(ref) { return nil }
    guard let node = registry[ref], let nested = node["$value"] else { return s }
    return resolveValue(nested, visited: visited.union([ref]))
  }
  return value
}

/// Resolves to Double for number/spacing/sizing/borderRadius/borderWidth/fontSizes.
func resolveNumber(_ value: Any) -> Double? {
  let resolved = resolveValue(value) ?? value
  if let n = resolved as? Double { return n }
  if let n = resolved as? Int { return Double(n) }
  if let s = resolved as? String, let n = Double(s) { return n }
  return nil
}

/// Resolves to a hex color `(uppercase, no '#')` plus alpha. Handles `#RRGGBB` and `rgba(r,g,b,a)`.
func resolveHex(_ value: Any) -> (hex: String, alpha: Double)? {
  let resolved = resolveValue(value) ?? value
  guard let s = resolved as? String else { return nil }
  if s.hasPrefix("#") {
    return (String(s.dropFirst()).uppercased(), 1.0)
  }
  if s.hasPrefix("rgba(") {
    let inner = s.replacingOccurrences(of: "rgba(", with: "").replacingOccurrences(of: ")", with: "")
    let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    if parts.count == 4,
       let r = Double(parts[0]), let g = Double(parts[1]), let b = Double(parts[2]), let a = Double(parts[3])
    {
      let hex = String(format: "%02X%02X%02X", Int(r), Int(g), Int(b))
      return (hex, a)
    }
  }
  return nil
}

// MARK: - Naming helpers

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

func capitalizeFirst(_ s: String) -> String {
  s.prefix(1).uppercased() + s.dropFirst()
}

func lowerFirst(_ s: String) -> String {
  s.prefix(1).lowercased() + s.dropFirst()
}

func camelCase(_ segs: [String]) -> String {
  guard let first = segs.first else { return "" }
  let head = lowerFirst(first)
  let tail = segs.dropFirst().map(capitalizeFirst).joined()
  return swiftKey(head + tail)
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
// Source: SWYP-Find/design-tokens repo (primitive.json / semantic.json / component.json)
"""

// MARK: - Color emission

var hexToColorName: [String: String] = [:]

func emitColor(name: String, value: Any, into lines: inout [String]) {
  guard let parts = resolveHex(value) else { return }
  if parts.alpha >= 1.0, let existing = hexToColorName[parts.hex] {
    lines.append("  static var \(name): Color { .\(existing) }")
  } else {
    lines.append("  static var \(name): Color { \(colorBody(hex: parts.hex, alpha: parts.alpha)) }")
    if parts.alpha >= 1.0 { hexToColorName[parts.hex] = name }
  }
}

var colorLines: [String] = [header, "", "import SwiftUI", "", "public extension ShapeStyle where Self == Color {", ""]

// Primitive color scales: primary / secondary / beige / gray (50..900).
let primitiveColorGroups = ["primary", "secondary", "beige", "gray"]
let scales = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]
for group in primitiveColorGroups {
  guard let g = primitive[group] as? [String: Any] else { continue }
  colorLines.append("  // MARK: - Primitive / \(capitalizeFirst(group))")
  for s in scales {
    guard let node = g[s] as? [String: Any], let v = node["$value"] else { continue }
    emitColor(name: "\(group)\(s)", value: v, into: &colorLines)
  }
  colorLines.append("")
}

// Backward-compat aliases: `neutral{N}` → `gray{N}`. Earlier call sites used `neutral*`
// before the upstream rename to `gray*`. Keep emitting both so existing usages compile;
// new code should prefer `gray*`.
if primitive["gray"] != nil {
  colorLines.append("  // MARK: - Compat / Neutral (alias of Gray)")
  for s in scales {
    colorLines.append("  static var neutral\(s): Color { .gray\(s) }")
  }
  colorLines.append("")
}

// Primitive status colors (error / warning, including alpha variants — typo "slpha" normalized).
colorLines.append("  // MARK: - Primitive / Status")
for bucket in ["error", "warning"] {
  guard let b = primitive[bucket] as? [String: Any] else { continue }
  for (rawKey, value) in b.sorted(by: { $0.key < $1.key }) {
    guard let node = value as? [String: Any], let v = node["$value"] else { continue }
    let key = (rawKey == "slpha") ? "alpha" : rawKey
    emitColor(name: camelCase([bucket, key]), value: v, into: &colorLines)
  }
}

colorLines.append("")

// Semantic colors — flat names walked from the tree.
func walkColorLeaves(
  _ node: [String: Any],
  path: [String],
  emit: (_ flatName: String, _ value: Any) -> Void
) {
  for (key, value) in node.sorted(by: { $0.key < $1.key }) {
    guard let dict = value as? [String: Any] else { continue }
    if let type = dict["$type"] as? String, let val = dict["$value"] {
      if type == "color" {
        emit(camelCase(path + [key]), val)
      }
    } else {
      walkColorLeaves(dict, path: path + [key], emit: emit)
    }
  }
}

let semanticColorRoots: [(jsonKey: String, prefix: String)] = [
  ("background", "bg"),
  ("text", "text"),
  ("border", "border"),
  ("surface", "surface"),
  ("action", "action"),
  ("icon", "icon"),
]
for (root, prefix) in semanticColorRoots {
  guard let group = semantic[root] as? [String: Any] else { continue }
  colorLines.append("  // MARK: - Semantic / \(capitalizeFirst(root))")
  walkColorLeaves(group, path: [prefix]) { name, val in
    emitColor(name: name, value: val, into: &colorLines)
  }
  colorLines.append("")
}

// Component colors — flat.
colorLines.append("  // MARK: - Component")
var componentNumberEntries: [(name: String, value: String)] = []

func walkComponent(_ node: [String: Any], path: [String]) {
  for (key, value) in node.sorted(by: { $0.key < $1.key }) {
    guard let dict = value as? [String: Any] else { continue }
    if let type = dict["$type"] as? String, let val = dict["$value"] {
      let name = camelCase(path + [key])
      switch type {
      case "color":
        emitColor(name: name, value: val, into: &colorLines)
      case "sizing", "spacing", "borderRadius", "borderWidth", "number":
        if let n = resolveNumber(val) {
          componentNumberEntries.append((name, formatNumber(n)))
        }
      default:
        break
      }
    } else {
      walkComponent(dict, path: path + [key])
    }
  }
}

walkComponent(component, path: [])

colorLines.append("}")
colorLines.append("")
try writeFile(colorOut, colorLines.joined(separator: "\n"))

// MARK: - Spacing (primitive + semantic gap/padding/border-width)

var spacingLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]

spacingLines.append("  // MARK: - Primitive Spacing")
var spacingPairs: [(value: Int, line: String)] = []
for (key, value) in primitive {
  guard key.hasPrefix("spacing-") || key.hasPrefix("spscing-") else { continue }
  guard let node = value as? [String: Any],
        let v = node["$value"],
        let n = resolveNumber(v) else { continue }
  let suffix = key.replacingOccurrences(of: "spacing-", with: "").replacingOccurrences(of: "spscing-", with: "")
  guard let intVal = Int(suffix) else { continue }
  spacingPairs.append((intVal, "  static let s\(intVal): CGFloat = \(formatNumber(n))"))
}

for (_, line) in spacingPairs.sorted(by: { $0.value < $1.value }) {
  spacingLines.append(line)
}

spacingLines.append("")

spacingLines.append("  // MARK: - Primitive Sizing")
for group in ["icon", "avatar", "control"] {
  guard let g = primitive[group] as? [String: Any] else { continue }
  for (sizeKey, value) in g.sorted(by: { $0.key < $1.key }) {
    guard let node = value as? [String: Any], let v = node["$value"], let n = resolveNumber(v) else { continue }
    spacingLines.append("  static let \(camelCase([group, sizeKey])): CGFloat = \(formatNumber(n))")
  }
}

spacingLines.append("")

if let gap = semantic["gap"] as? [String: Any] {
  spacingLines.append("  // MARK: - Semantic Gap")
  var gapPairs: [(Int, String)] = []
  for (key, value) in gap {
    guard let node = value as? [String: Any], let v = node["$value"], let n = resolveNumber(v),
          let intKey = Int(key) else { continue }
    gapPairs.append((intKey, "  static let gap\(intKey): CGFloat = \(formatNumber(n))"))
  }
  for (_, line) in gapPairs.sorted(by: { $0.0 < $1.0 }) {
    spacingLines.append(line)
  }
  spacingLines.append("")
}

if let padding = semantic["padding"] as? [String: Any] {
  spacingLines.append("  // MARK: - Semantic Padding")
  var paddingLines: [String] = []
  func walkPadding(_ node: [String: Any], path: [String]) {
    for (key, value) in node.sorted(by: { $0.key < $1.key }) {
      guard let dict = value as? [String: Any] else { continue }
      if let type = dict["$type"] as? String, let val = dict["$value"] {
        if type == "spacing", let n = resolveNumber(val) {
          paddingLines.append("  static let \(camelCase(path + [key])): CGFloat = \(formatNumber(n))")
        }
      } else {
        walkPadding(dict, path: path + [key])
      }
    }
  }
  walkPadding(padding, path: ["padding"])
  spacingLines.append(contentsOf: paddingLines)
  spacingLines.append("")
}

spacingLines.append("  // MARK: - Semantic Border Width")
for variant in ["regular", "medium", "large"] {
  let key = "border-width-\(variant)"
  guard let node = semantic[key] as? [String: Any], let v = node["$value"], let n = resolveNumber(v) else { continue }
  spacingLines.append("  static let \(camelCase(["border", "width", variant])): CGFloat = \(formatNumber(n))")
}

spacingLines.append("}")
spacingLines.append("")
try writeFile(spacingOut, spacingLines.joined(separator: "\n"))

// MARK: - Radius

var radiusLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]
radiusLines.append("  // MARK: - Radius")
for key in ["radius-default", "radius-max"] {
  guard let node = semantic[key] as? [String: Any], let v = node["$value"], let n = resolveNumber(v) else { continue }
  let suffix = key.replacingOccurrences(of: "radius-", with: "")
  radiusLines.append("  static let \(camelCase(["radius", suffix])): CGFloat = \(formatNumber(n))")
}

radiusLines.append("}")
radiusLines.append("")
try writeFile(radiusOut, radiusLines.joined(separator: "\n"))

// MARK: - Component numerics (flat)

if !componentNumberEntries.isEmpty {
  var cnLines: [String] = [header, "", "import CoreGraphics", "", "public extension CGFloat {", ""]
  cnLines.append("  // MARK: - Component")
  for entry in componentNumberEntries.sorted(by: { $0.name < $1.name }) {
    cnLines.append("  static let \(entry.name): CGFloat = \(entry.value)")
  }
  cnLines.append("}")
  cnLines.append("")
  try writeFile(componentNumberOut, cnLines.joined(separator: "\n"))
}

// MARK: - ComponentToken (nested forwarding enum)

func walkComponentNested(
  _ node: [String: Any],
  path: [String],
  indent: String,
  out: inout [String]
) {
  let leafKeys = node.keys.sorted().filter {
    guard let d = node[$0] as? [String: Any] else { return false }
    return d["$type"] != nil
  }
  let groupKeys = node.keys.sorted().filter {
    guard let d = node[$0] as? [String: Any] else { return false }
    return d["$type"] == nil
  }
  for key in leafKeys {
    guard let child = node[key] as? [String: Any], let type = child["$type"] as? String else { continue }
    let flat = camelCase(path + [key])
    switch type {
    case "color":
      out.append("\(indent)public static var \(swiftKey(key)): Color { .\(flat) }")
    case "sizing", "spacing", "borderRadius", "borderWidth", "number":
      out.append("\(indent)public static var \(swiftKey(key)): CGFloat { .\(flat) }")
    default:
      continue
    }
  }
  for (i, key) in groupKeys.enumerated() {
    guard let child = node[key] as? [String: Any] else { continue }
    if i == 0, !leafKeys.isEmpty { out.append("") }
    if i > 0 { out.append("") }
    out.append("\(indent)public enum \(capitalizeFirst(key)) {")
    walkComponentNested(child, path: path + [key], indent: indent + "  ", out: &out)
    out.append("\(indent)}")
  }
}

var ctLines: [String] = [header, "", "import SwiftUI", "", "public enum ComponentToken {"]
walkComponentNested(component, path: [], indent: "  ", out: &ctLines)
ctLines.append("}")
ctLines.append("")
try writeFile(componentTokenOut, ctLines.joined(separator: "\n"))

print("[token-gen] done. source=\(sourceDir)")
