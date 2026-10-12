//
//  ClassReportDependencyTests.swift
//  ClassDomainTests
//
//  Created by Picke on 10/11/26.
//

import ClassDomain
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

struct ClassReportDependencyTests {
  @Test
  func 리포트_원본_문구와_의견을_그대로_보존한다() {
    #expect(MockClassReport.figma.texts == [
      .aiSummaryTitle: "이번 토론에서 생각의 기준이 넓어졌어요",
      .aiSummaryDetail: "마지막 의견에서는 재범을 줄이는 방법으로 교육과 보호를 중요하게 봤어요.",
      .teacherSummary: "“왜 생각이 달라졌는지 자신의 말로 설명한 점이 좋았어요”",
      .commentStance: "낮춰야한다",
      .commentDate: "26.09.23. 14:02",
      .commentBody: "촉법소년 연령을 낮추는 것만으로는 재범을 막기 어려워요. 피해자를 보호하면서 교육과 교정도 함께 해야 한다고 생각해요.",
      .commentLikes: "1,340",
      .commentReplies: "23",
      .replyAuthor: "김민지 · 교정이 우선이다",
      .replyParent: "촉법소년 연령을 낮추는 것만으로는 재범을 막기 어려워요.",
      .replyBody: "토론을 들으면서 처벌만으로는 해결되지 않는 점을 이해하게 됐어요. 교육과 보호도 함께 필요하다고 생각해요.",
      .replyDate: "26.09.23. 14:02",
      .replyLikes: "12",
      .participantTitle: "참여한 학생",
      .participantCount: "28 / 32",
      .classSummary: "입장을 바꾼 학생은 6명이에요.\n연령하향 → 교정우선 5명, 교정 우선 → 연령 하향 1명이에요.\n교정 우선 선택은 10명에서 14명으로 늘었어요.",
      .bestAuthor: "김민지 · 교정이 우선이다",
      .bestBody: "“피해자 보호를 위한 기준도 함께 필요하지 않을까요?”",
      .bestLikes: "1,340",
      .bestReplies: "23",
      .feedbackTitle1: "처벌의 필요성에서 교정 가능성까지 함께 보기 시작했어요",
      .feedbackDetail1: "“처벌만으로는 해결되지 않는다”는 반대 의견에 그치지 않고, 교육과 보호라는 대안을 제시했어요. 해결 방법까지 논의를 이어 간 점이 좋았어요.",
      .feedbackTitle2: "반대하는 데서 끝나지 않고 다른 해결 방향을 제시했어요",
      .feedbackDetail2: "교육과 보호가 어떤 상황에서 효과적일지는 아직 설명되지 않았어요. 대안을 제시한 만큼, 그 대안이 효과를 낼 조건을 덧붙이면 주장이 더 분명해져요.",
      .feedbackTitle3: "근거를 한 단계 더 구체적으로",
      .feedbackDetail3: "교육과 보호가 재범을 줄이려면, 어떤 조건이 가장 먼저 갖춰져야 할까요?",
      .nextQuestion: "처벌과 교화를 함께 한다면,\n무엇을 기준으로 균형을 잡을까요?",
      .nextHint: "내 의견과 반대되는 입장도 함께 떠올려 보세요.",
      .teacherFeedback: "처음과 나중의 생각이 어떻게 달라졌는지 스스로 정리한 점이 좋았어요. 단순히 입장을 바꾸는 데서 끝나지 않고, 왜 바뀌었는지 설명하려는 태도가 인상적이었습니다.",
      .teacherName: "김민지 선생님",
      .teacherDate: "26.09.23. 14:02",
      .initialChoice: "낮춰야 한다",
      .finalChoice: "교정이 우선이다",
      .commentCount: "2",
      .replyCount: "3",
      .receivedLikeCount: "12",
    ])
    #expect(MockClassReport.figma.myOpinions == [
      "처벌만으로 문제를 해결하기보다 교육과 보호의 역할도 함께 생각해야 한다고 봐요.",
      "피해자의 안전을 지키면서도 다시 같은 일이 일어나지 않게 도울 방법이 필요해요.",
      "토론을 들으며 연령만 낮추는 것보다 교정의 기준을 세우는 일이 중요하다고 느꼈어요.",
    ])
    #expect(MockClassReport.figma.layout == .summary)
    #expect(MockClassReport.figma[.aiSummaryTitle] == "이번 토론에서 생각의 기준이 넓어졌어요")
  }

  @Test
  func 기본_리포트와_운영자_대시보드는_원래_목_방에만_시드된다() async throws {
    let repository = MockClassRepository()
    #expect(try await repository.fetchReport(roomID: ClassRoom.mockClosedSociety.id) == MockClassReport.figma)
    #expect(try await repository.fetchOwnerDashboard(roomID: ClassRoom.mocks[0].id) == MockClassOwnerDashboard.figma)
    #expect(MockClassReport.figma[.teacherName] == "김민지 선생님")
    #expect(MockClassReport.figma[.initialChoice] == "낮춰야 한다")
    #expect(MockClassReport.figma.myOpinions.count == 3)
    #expect(MockClassReport.figma.initialVoteLeading == 0.64)
    #expect(MockClassReport.figma.finalVoteLeading == 0.50)
    #expect(MockClassOwnerDashboard.figma.members.count == 32)
    #expect(MockClassOwnerDashboard.figma.opinions.count == 3)
    #expect(MockClassOwnerDashboard.figma.insight ==
      "촉법소년 연령 하향에 관한 의견과 함께 피해자 보호, 교육 및 교정의 필요성을 논의했어요.")
    let ownerReport = try #require(MockClassOwnerDashboard.figma.report)
    let memberReport = MockClassReport.figma
    #expect(ownerReport[.aiSummaryDetail] == MockClassOwnerDashboard.figma.insight)
    #expect(ownerReport[.feedbackDetail1] ==
      "처음에는 범죄에 대한 책임을 중요하게 봤지만, 대화를 거치며 재범을 줄이기 위한 교육과 보호의 역할도 함께 고려했어요.")
    #expect(ownerReport[.feedbackDetail2] ==
      "“처벌만으로는 해결되지 않는다”는 생각에서 한 걸음 더 나아가 교육과 보호라는 대안을 의견에 덧붙였어요.")
    var ownerOtherTexts = ownerReport.texts
    var memberOtherTexts = memberReport.texts
    for key in [ClassReport.Key.aiSummaryDetail, .feedbackDetail1, .feedbackDetail2] {
      ownerOtherTexts.removeValue(forKey: key)
      memberOtherTexts.removeValue(forKey: key)
    }
    #expect(ownerOtherTexts == memberOtherTexts)
    #expect(ownerReport.myOpinions == memberReport.myOpinions)
    #expect(ownerReport.initialVoteLeading == memberReport.initialVoteLeading)
    #expect(ownerReport.finalVoteLeading == memberReport.finalVoteLeading)
    #expect(ownerReport.layout == memberReport.layout)
    #expect(MockClassOwnerDashboard.figma.metrics == ClassParticipationMetrics(
      commentAuthorCount: 24,
      optionAVoteCount: 18,
      optionBVoteCount: 10
    ))
    #expect(try await repository.fetchReport(roomID: ClassRoom.mocks[1].id) == nil)
    #expect(try await repository.fetchOwnerDashboard(roomID: ClassRoom.mocks[1].id) == nil)
  }

  @Test
  func 빈_맵은_기본_시드를_억제하고_임의_데이터를_주입할_수_있다() async throws {
    let defaultRoom = ClassRoom.mocks[0]
    let empty = MockClassRepository(rooms: [defaultRoom], availableRooms: [], reports: [:], dashboards: [:])
    #expect(try await empty.fetchReport(roomID: defaultRoom.id) == nil)
    #expect(try await empty.fetchOwnerDashboard(roomID: defaultRoom.id) == nil)

    let arbitraryRoom = ClassRoom(
      id: 87,
      name: "임의 클래스",
      joinCode: "ARBITRARY",
      battle: .mocks[0],
      deadline: .distantFuture,
      memberCount: 2,
      role: .owner,
      status: .open,
      allowsAnonymousOpinion: false,
      requiresComment: false
    )
    let report = ClassReport(
      texts: [.teacherName: "새 교사"],
      myOpinions: ["새 의견"],
      initialVoteLeading: 0.25,
      finalVoteLeading: 0.75,
      layout: .tabbed
    )
    let dashboard = ClassOwnerDashboardData(members: [], opinions: [], report: report, metrics: nil)
    let injected = MockClassRepository(
      rooms: [arbitraryRoom],
      availableRooms: [],
      reports: [87: report, 999: report],
      dashboards: [87: dashboard, 999: dashboard]
    )
    #expect(try await injected.fetchReport(roomID: 87) == report)
    #expect(try await injected.fetchOwnerDashboard(roomID: 87) == dashboard)
    do {
      _ = try await injected.fetchReport(roomID: 999)
      Issue.record("초기 방 목록에 없는 ID가 읽혔습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }

    let separate = MockClassRepository(rooms: [arbitraryRoom], availableRooms: [], reports: [:], dashboards: [:])
    #expect(try await separate.fetchReport(roomID: arbitraryRoom.id) == nil)
    #expect(try await separate.fetchOwnerDashboard(roomID: arbitraryRoom.id) == nil)
  }

  @Test
  func 참여전_방과_삭제된_방은_읽을_수_없고_첫_참여에는_이전_리포트가_없다() async throws {
    let room = ClassRoom.mockJoinable
    let repository = MockClassRepository(rooms: [], availableRooms: [room])
    do {
      _ = try await repository.fetchReport(roomID: room.id)
      Issue.record("참여 전 리포트가 읽혔습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
    _ = try await repository.joinClass(joinCode: room.joinCode, nickname: "학생")
    #expect(try await repository.fetchReport(roomID: room.id) == nil)

    let owner = ClassRoom.mocks[0]
    let ownerRepository = MockClassRepository(rooms: [owner], availableRooms: [])
    try await ownerRepository.deleteClass(id: owner.id)
    do {
      _ = try await ownerRepository.fetchOwnerDashboard(roomID: owner.id)
      Issue.record("삭제된 방의 대시보드가 읽혔습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
  }

  @Test
  func 멤버는_주입된_대시보드도_볼_수_없다() async throws {
    let member = ClassRoom.mockClosedSociety
    let repository = MockClassRepository(
      rooms: [member],
      availableRooms: [],
      dashboards: [member.id: MockClassOwnerDashboard.figma]
    )
    do {
      _ = try await repository.fetchOwnerDashboard(roomID: member.id)
      Issue.record("멤버가 운영자 대시보드를 읽었습니다")
    } catch {
      #expect(error as? ClassError == .unknown("클래스 관리자만 대시보드를 볼 수 있습니다."))
    }
  }

  @Test
  func 생성_ID가_기존_시드와_겹쳐도_새_방은_데이터를_상속하지_않는다() async throws {
    for initialRooms in [[], [ClassRoom.mocks[0]]] {
      let repository = MockClassRepository(rooms: initialRooms, availableRooms: [])
      for _ in 1 ... 5 {
        let room = try await repository.createClass(ClassCreation(
          name: "새 수업",
          deadline: .distantFuture,
          battleId: ClassBattleSummary.mocks[0].id,
          allowsAnonymousOpinion: false,
          requiresComment: false
        ))
        #expect(try await repository.fetchReport(roomID: room.id) == nil)
        #expect(try await repository.fetchOwnerDashboard(roomID: room.id) == nil)
      }
    }
  }

  @Test
  func 마감일_수정은_대시보드_시드를_유지한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      reports: [room.id: MockClassReport.figma]
    )
    let deadline = room.deadline.addingTimeInterval(3600)
    let updated = try await repository.updateDeadline(id: room.id, deadline: deadline)
    #expect(updated.deadline == deadline)
    #expect(updated.role == .owner)
    #expect(try await repository.fetchReport(roomID: room.id) == MockClassReport.figma)
    #expect(try await repository.fetchOwnerDashboard(roomID: room.id) == MockClassOwnerDashboard.figma)
  }

  @Test
  func 회원_삭제와_이름_수정은_대시보드_회원만_갱신한다() async throws {
    let room = ClassRoom.mocks[0]
    let report = ClassReport(
      texts: [.teacherName: "주입한 교사"],
      myOpinions: ["주입한 의견"],
      initialVoteLeading: 0.2,
      finalVoteLeading: 0.8,
      layout: .tabbed
    )
    let metrics = ClassParticipationMetrics(commentAuthorCount: 7, optionAVoteCount: 3, optionBVoteCount: 4)
    let owner = ClassOwnerMember(id: 1, name: "옛 운영자", participationCount: 9, needsReview: true)
    let removed = ClassOwnerMember(id: 2, name: "나갈 회원", participationCount: 5)
    let remaining = ClassOwnerMember(id: 3, name: "남은 회원", participationCount: 2, needsReview: true)
    let dashboard = ClassOwnerDashboardData(
      members: [owner, removed, remaining],
      opinions: MockClassOwnerDashboard.figma.opinions,
      report: report,
      metrics: metrics,
      insight: "주입한 운영자 요약"
    )
    let repository = MockClassRepository(
      rooms: [room], availableRooms: [], reports: [:], dashboards: [room.id: dashboard]
    )

    _ = try await repository.removeMember(roomID: room.id, memberID: 2, currentMemberID: 1)
    _ = try await repository.updateDisplayName(
      roomID: room.id, memberID: 1, currentMemberID: 1, name: " 새 운영자 "
    )

    #expect(try await repository.fetchOwnerDashboard(roomID: room.id) == ClassOwnerDashboardData(
      members: [
        ClassOwnerMember(id: 1, name: "새 운영자", participationCount: 9, needsReview: true),
        remaining,
      ],
      opinions: dashboard.opinions,
      report: report,
      metrics: metrics,
      insight: "주입한 운영자 요약"
    ))
  }

  @Test
  func 유스케이스는_리포트_성공_nil_및_오류를_그대로_전달한다() async throws {
    let room = ClassRoom.mocks[0]
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      reports: [room.id: MockClassReport.figma],
      dashboards: [:]
    )
    let useCase = withDependencies {
      $0.classRepository = repository
    } operation: {
      ClassUseCaseImpl()
    }
    #expect(try await useCase.fetchReport(roomID: room.id) == MockClassReport.figma)
    #expect(try await useCase.fetchOwnerDashboard(roomID: room.id) == nil)
    do {
      _ = try await useCase.fetchReport(roomID: 999)
      Issue.record("유스케이스가 오류를 삼켰습니다")
    } catch {
      #expect(error as? ClassError == .invalidCode)
    }
    do {
      _ = try await ClassRepositoryImpl().fetchOwnerDashboard(roomID: room.id)
      Issue.record("라이브 저장소가 없는 API에서 데이터를 반환했습니다")
    } catch {
      #expect(error as? ClassError == .network("클래스 서버 API가 연결되지 않았습니다."))
    }
    do {
      _ = try await ClassRepositoryImpl().fetchReport(roomID: room.id)
      Issue.record("라이브 저장소가 없는 API에서 리포트를 반환했습니다")
    } catch {
      #expect(error as? ClassError == .network("클래스 서버 API가 연결되지 않았습니다."))
    }
  }
}
