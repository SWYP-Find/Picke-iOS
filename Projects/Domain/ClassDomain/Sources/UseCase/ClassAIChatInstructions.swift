//
//  ClassAIChatInstructions.swift
//  ClassDomain
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface

enum ClassAIChatInstructions {
  static func make(context: ClassAIChatContext) -> String {
    var lines = [
      "토론 질문: \(context.question)",
      "사용자는 '\(context.selectedStance)' 입장을 골랐습니다.",
      "당신은 '\(context.opponentStance)' 입장을 대변하는 토론 상대입니다.",
    ]
    if let name = context.opponentPhilosopherName {
      lines.append("\(name)의 관점에서 논의하세요.")
    }
    lines += [
      "한국어로만 답하고, 사용자의 의견에 정중하게 반박하세요.",
      "역사적 인용을 꾸며내지 마세요.",
      "한 차례 답변은 짧은 문장 1~3개, 총 240자 이내로 작성하세요. 질문이나 반론으로 끝내세요.",
      "단, '마지막 라운드' 안내를 받으면 질문하지 말고 지금까지의 논점을 정리하며 마무리하세요.",
    ]
    return lines.joined(separator: "\n")
  }

  /// 마지막 라운드 응답 요청 — 사용자 의견 뒤에 마무리 안내를 붙인다.
  static func finalRoundPrompt(_ text: String) -> String {
    [
      text,
      "마지막 라운드입니다. 질문하지 말고 지금까지의 논점을 정리하며 마무리하세요.",
    ].joined(separator: "\n\n")
  }
}
