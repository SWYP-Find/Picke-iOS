@testable import ClassDomain
import ClassDomainInterface
import Foundation
import PickeNetwork
import Testing

struct ClassTopicAPIContractTests {
  @Test
  func 초안_생성과_후보_선택은_서버_계약의_필드로_인코딩한다() throws {
    let filter = ClassTopicFilter(keyword: " 뫼르소 ", level: .high, categories: [.literature, .philosophy])
    let creation = ClassTopicDraftService.create(filter)
    let selection = ClassTopicDraftService.select(draftID: 7, batchNo: 2, candidateID: 3)
    let creationParameters = try #require(creation.parameters)
    let selectionParameters = try #require(selection.parameters)
    let creationData = try JSONEncoder().encode(creationParameters)
    let selectionData = try JSONEncoder().encode(selectionParameters)
    let creationBody = try #require(JSONSerialization.jsonObject(with: creationData) as? [String: Any])
    let selectionBody = try #require(JSONSerialization.jsonObject(with: selectionData) as? [String: Int])

    #expect(try creation.url().path == "/api/v1/class-topic-drafts")
    #expect(creationBody["topicSeed"] as? String == "뫼르소")
    #expect(creationBody["difficulty"] as? String == "INTERMEDIATE")
    #expect(creationBody["categories"] as? [String] == ["문학", "철학"])
    #expect(try selection.url().path == "/api/v1/class-topic-drafts/7/selection")
    #expect(selectionBody == ["batchNo": 2, "candidateId": 3])
  }

  @Test
  func 초안_응답은_후보와_선택한_버전_ID를_보존한다() throws {
    let json = """
    {
      "draftId":7,"topicSeed":"뫼르소","difficulty":"INTERMEDIATE","categories":["문학"],
      "suggestStatus":"SUCCEEDED","clarificationMessage":null,"batchNo":2,
      "remainingSuggestions":1,"remainingValidations":3,
      "candidates":[{
        "candidateId":3,"question":"감정을 표현해야 하나요?","description":"표현의 자유",
        "category":"문학","difficulty":"INTERMEDIATE",
        "options":[
          {"label":"해야 한다","rationale":"공감","philosopher":"KANT"},
          {"label":"선택이다","rationale":"자유","philosopher":null}
        ]
      }],
      "latestVersion":null
    }
    """
    let draft = try JSONDecoder().decode(ClassTopicDraftDTO.self, from: Data(json.utf8)).toDomain()

    #expect(draft.id == 7)
    #expect(draft.batchNo == 2)
    #expect(draft.candidates.first?.id == 3)
    #expect(draft.candidates.first?.options[0].philosopher == "KANT")
  }
}
