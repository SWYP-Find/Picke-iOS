@testable import ClassDomain
import ClassDomainInterface
import Testing

struct ClassAIChatInstructionsTests {
  @Test
  func 이름있는_상대의_질문과_입장을_완전한_지시문으로_만든다() {
    let context = ClassAIChatContext(
      question: "슬픔을 드러내지 않은 뫼르소를 비난할 수 있을까?",
      selectedStance: "비난할 수 있다",
      opponentStance: "유지해야 한다",
      opponentPhilosopherName: "플라톤"
    )

    #expect(ClassAIChatInstructions.make(context: context) == """
    토론 질문: 슬픔을 드러내지 않은 뫼르소를 비난할 수 있을까?
    사용자는 '비난할 수 있다' 입장을 골랐습니다.
    당신은 '유지해야 한다' 입장을 대변하는 토론 상대입니다.
    플라톤의 관점에서 논의하세요.
    한국어로만 답하고, 사용자의 의견에 정중하게 반박하세요.
    역사적 인용을 꾸며내지 마세요.
    한 차례 답변은 짧은 문장 1~3개, 총 240자 이내로 작성하세요. 질문이나 반론으로 끝내세요.
    """)
  }

  @Test
  func 이름없는_상대에게_철학자_페르소나를_만들지_않는다() {
    let context = ClassAIChatContext(
      question: "재판에서 삶의 태도까지 판단 근거가 되어도 될까?",
      selectedStance: "고려해도 된다",
      opponentStance: "범죄만 봐야 한다",
      opponentPhilosopherName: nil
    )

    #expect(ClassAIChatInstructions.make(context: context) == """
    토론 질문: 재판에서 삶의 태도까지 판단 근거가 되어도 될까?
    사용자는 '고려해도 된다' 입장을 골랐습니다.
    당신은 '범죄만 봐야 한다' 입장을 대변하는 토론 상대입니다.
    한국어로만 답하고, 사용자의 의견에 정중하게 반박하세요.
    역사적 인용을 꾸며내지 마세요.
    한 차례 답변은 짧은 문장 1~3개, 총 240자 이내로 작성하세요. 질문이나 반론으로 끝내세요.
    """)
  }

  @Test
  func 반대쪽_선택지도_질문과_두_입장을_보존한다() {
    let contexts = [
      ClassAIChatContext(
        question: "슬픔을 드러내지 않은 뫼르소를 비난할 수 있을까?",
        selectedStance: "유지해야 한다",
        opponentStance: "비난할 수 있다",
        opponentPhilosopherName: "사르트르"
      ),
      ClassAIChatContext(
        question: "재판에서 삶의 태도까지 판단 근거가 되어도 될까?",
        selectedStance: "범죄만 봐야 한다",
        opponentStance: "고려해도 된다",
        opponentPhilosopherName: nil
      ),
    ]

    for context in contexts {
      let instructions = ClassAIChatInstructions.make(context: context)
      #expect(instructions.contains(context.question))
      #expect(instructions.contains(context.selectedStance))
      #expect(instructions.contains(context.opponentStance))
      #expect(instructions.contains("한국어로만 답하고"))
      #expect(instructions.contains("정중하게 반박하세요"))
      #expect(instructions.contains("역사적 인용을 꾸며내지 마세요"))
      #expect(instructions.contains("짧은 문장 1~3개, 총 240자 이내"))
      #expect(instructions.contains("질문이나 반론으로 끝내세요"))
      if let name = context.opponentPhilosopherName {
        #expect(instructions.contains(name))
      } else {
        #expect(!instructions.contains("철학자"))
      }
    }
  }
}
