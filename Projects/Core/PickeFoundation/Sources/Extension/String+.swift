//
//  String+Sentence.swift
//  PickeFoundation
//

import Foundation

public extension String {
  /// 문장 끝(`. ? !` / 줄바꿈) 기준으로 분할한다. 구분자는 포함, 공백뿐인 조각은 제외.
  /// 분할 결과가 없으면 원본 1개를 그대로 반환.
  func splitIntoSentences() -> [String] {
    var result: [String] = []
    var current = ""
    for character in self {
      current.append(character)
      if character == "." || character == "?" || character == "!" || character == "\n" {
        if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          result.append(current)
        }
        current = ""
      }
    }
    if !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      result.append(current)
    }
    return result.isEmpty ? [self] : result
  }
}
