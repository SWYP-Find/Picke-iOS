//
//  ClassAIChatMessageUseCase.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import Foundation

enum ClassAIChatMessageUseCase {
  private static let maxLength = 300
  private static let terminators: Set<Character> = [".", "!", "?", "。", "…"]
  private static let closers: Set<Character> = ["\"", "'", "”", "’", ")", "」", "』"]

  /// 모델 출력을 문장 단위로 나눠 최대 세 개의 짧은 말풍선을 만든다.
  /// - 줄바꿈, 또는 종결부호(연속 부호·닫는 따옴표 포함) 뒤에 공백이나 끝이 올 때만 자른다. `3.5` 같은 숫자는 자르지 않는다.
  /// - 전체 길이(합치는 공백 포함)가 300자를 넘으면 문장 경계에서 자른다. 첫 문장은 길어도 자르지 않는다.
  static func bubbles(from response: String) -> [String] {
    let pieces = limited(sentences(in: response))
    if pieces.count <= 3 {
      return pieces
    }
    return Array(pieces.prefix(2)) + [pieces.dropFirst(2).joined(separator: " ")]
  }

  private static func sentences(in text: String) -> [String] {
    let characters = Array(text)
    var sentences: [String] = []
    var current = ""
    var index = 0
    while index < characters.count {
      let character = characters[index]
      current.append(character)
      index += 1
      if character == "\n" {
        append(current, to: &sentences)
        current = ""
        continue
      }
      guard terminators.contains(character) else { continue }
      while index < characters.count,
            terminators.contains(characters[index]) || closers.contains(characters[index])
      {
        current.append(characters[index])
        index += 1
      }
      if index == characters.count || characters[index].isWhitespace {
        append(current, to: &sentences)
        current = ""
      }
    }
    append(current, to: &sentences)
    return sentences
  }

  private static func append(
    _ piece: String,
    to sentences: inout [String]
  ) {
    let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmed.isEmpty {
      sentences.append(trimmed)
    }
  }

  /// 첫 문장은 길어도 중간에서 자르지 않는다.
  /// 이후 문장은 말풍선을 합칠 때 들어가는 공백까지 포함해 300자 안에 들어올 때만 붙인다.
  private static func limited(_ sentences: [String]) -> [String] {
    guard let first = sentences.first else { return [] }
    var result = [first]
    var length = first.count
    for sentence in sentences.dropFirst() {
      let nextLength = length + 1 + sentence.count
      guard nextLength <= maxLength else { break }
      result.append(sentence)
      length = nextLength
    }
    return result
  }
}
