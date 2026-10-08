import Foundation

enum ClassAIChatMessageUseCase {
  /// 모델 출력의 줄바꿈과 문장 부호를 기준으로 최대 세 개의 짧은 말풍선을 만든다.
  static func bubbles(from response: String) -> [String] {
    let text = String(response.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
    guard !text.isEmpty else { return [] }
    var pieces: [String] = []
    var current = ""
    for character in text {
      current.append(character)
      if character == "\n" || ".!?。".contains(character) {
        let piece = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !piece.isEmpty {
          pieces.append(piece)
        }
        current = ""
      }
    }
    let rest = current.trimmingCharacters(in: .whitespacesAndNewlines)
    if !rest.isEmpty {
      pieces.append(rest)
    }
    if pieces.count <= 3 {
      return pieces
    }
    return Array(pieces.prefix(2)) + [pieces.dropFirst(2).joined(separator: " ")]
  }
}
