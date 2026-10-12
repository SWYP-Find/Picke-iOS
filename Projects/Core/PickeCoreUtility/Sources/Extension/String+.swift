//
//  String+.swift
//  PickeCoreUtility
//
//  Created by Picke on 10/11/26.
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

  /// 마지막 글자의 받침 유무로 조사를 고른다 (예: `"플라톤".josa("과", "와")` → `"과"`).
  /// 마지막 글자가 한글이 아니면 `"과(와)"` 처럼 함께 표기한다.
  func josa(
    _ withBatchim: String,
    _ withoutBatchim: String
  ) -> String {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard let scalar = trimmed.unicodeScalars.last, (0xAC00 ... 0xD7A3).contains(scalar.value) else {
      return "\(withBatchim)(\(withoutBatchim))"
    }
    return (scalar.value - 0xAC00) % 28 == 0 ? withoutBatchim : withBatchim
  }
}
