//
//  ClassReportTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import Testing

@MainActor
struct ClassReportTests {
  @Test
  func 결과_탭을_선택하면_해당_내용으로_바뀐다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
      ClassReportFeature()
    }

    await store.send(.view(.tabSelected(.classResult))) {
      $0.selectedTab = .classResult
    }
    await store.send(.view(.tabSelected(.classResult)))
    await store.send(.view(.tabSelected(.feedback))) {
      $0.selectedTab = .feedback
    }
  }

  @Test
  func 결과_뒤로가기는_코디네이터에_닫기를_알린다() async {
    let store = TestStore(initialState: ClassReportFeature.State(room: ClassRoom.mocks[0], instanceID: UUID())) {
      ClassReportFeature()
    }

    await store.send(.view(.backTapped))
    await store.receive(\.delegate.dismiss)
  }

  @Test
  func 주입된_리포트를_불러오고_중복_요청하지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let report = MockClassReport.figma
    let instanceID = UUID(1)
    let requestID = UUID(2)
    let repository = MockClassRepository(
      rooms: [room],
      availableRooms: [],
      reports: [room.id: report]
    )
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: instanceID)) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
      $0.isLoading = true
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.hasLoaded = true
      $0.isLoading = false
      $0.report = report
    }
    await store.send(.view(.onAppear))
    #expect(store.state.showsSummaryLayout)
  }

  @Test
  func 로딩_중_다시_나타나도_요청하지_않는다() async {
    var state = ClassReportFeature.State(room: .mockClosedSociety, instanceID: UUID(8))
    state.isLoading = true
    let store = TestStore(initialState: state) { ClassReportFeature() }

    await store.send(.view(.onAppear))
  }

  @Test
  func 없는_리포트는_네_탭을_유지하는_사용불가_상태다() async {
    let room = ClassRoom.mockClosedSociety
    let requestID = UUID(3)
    let repository = MockClassRepository(rooms: [room], availableRooms: [], reports: [:])
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: UUID(4))) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
      $0.isLoading = true
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.hasLoaded = true
      $0.isLoading = false
    }
    #expect(store.state.report == nil)
    #expect(!store.state.showsSummaryLayout)
    await store.send(.view(.tabSelected(.feedback))) {
      $0.selectedTab = .feedback
    }
  }

  @Test
  func 실패_후_재시도하고_늦은_응답은_무시한다() async {
    let room = ClassRoom.mockClosedSociety
    let instanceID = UUID(5)
    let requestID = UUID(6)
    let repository = MockClassRepository(rooms: [], availableRooms: [])
    let store = TestStore(initialState: ClassReportFeature.State(room: room, instanceID: instanceID)) {
      ClassReportFeature()
    } withDependencies: {
      $0.classUseCase = repository
      $0.uuid = .constant(requestID)
    }

    await store.send(.view(.onAppear))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
      $0.isLoading = true
    }
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.hasLoaded = true
      $0.isLoading = false
      $0.loadFailed = true
    }
    await store.send(.view(.retryTapped))
    await store.receive(\.async.fetch) {
      $0.requestID = requestID
      $0.isLoading = true
      $0.loadFailed = false
    }
    await store.send(.inner(.reportResponse(
      instanceID: UUID(7),
      requestID: requestID,
      roomID: room.id,
      .success(MockClassReport.figma)
    )))
    await store.receive(\.inner.reportResponse) {
      $0.requestID = nil
      $0.isLoading = false
      $0.loadFailed = true
    }
  }

  @Test
  func 뒤로가기_후_지연된_응답은_상태를_바꾸지_않는다() async {
    let room = ClassRoom.mockClosedSociety
    let instanceID = UUID(9)
    let requestID = UUID(10)
    var state = ClassReportFeature.State(room: room, instanceID: instanceID)
    state.requestID = requestID
    state.isLoading = true
    let store = TestStore(initialState: state) { ClassReportFeature() }

    await store.send(.view(.backTapped)) {
      $0.requestID = nil
      $0.isLoading = false
    }
    await store.receive(\.delegate.dismiss)
    await store.send(.inner(.reportResponse(
      instanceID: instanceID,
      requestID: requestID,
      roomID: room.id,
      .success(MockClassReport.figma)
    )))
  }
}

private extension UUID {
  init(_ value: UInt8) {
    self.init(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, value))
  }
}
