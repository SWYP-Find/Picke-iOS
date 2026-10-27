import AudioPlayerServiceInterface
@testable import Class
import BattleDomainInterface
import ClassDomainInterface
import ComposableArchitecture
import Foundation
import HomeDomainInterface
import PerspectiveDomainInterface
import Testing

@MainActor
struct ClassBattleFlowTests {
  private let requestID = UUID(uuidString: "00000000-0000-0000-0000-000000000042")!

  @Test
  func 이미_제출한_의견은_빈_재조회_응답으로_다시_작성할_수_없다() async {
    var state = battleState(room: .mocks[0])
    state.session = session(step: .completed, commentRequired: false)
    state.viewState = .loaded
    state.hasSubmittedInCurrentSession = true
    state.hasPublishedPerspective = true
    state.myPerspectiveRequestID = requestID
    let store = TestStore(initialState: state) { ClassBattleFlowFeature() }

    await store.send(.inner(.myPerspectiveResponse(requestID, .success([])))) {
      $0.myPerspectiveRequestID = nil
    }
    #expect(!store.state.shouldShowComposer)
  }

  @Test
  func 제출_중_화면을_이탈하면_재진입_시_서버_진행상태를_확인한다() async {
    let spy = ClassBattleFlowSpy()
    let serverSession = session(step: .postVote, commentRequired: false)
    let history = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: nil,
      status: .postVote,
      opinionChanged: nil
    )
    var state = battleState(room: .mocks[0])
    state.session = session(step: .postVote, commentRequired: false)
    state.viewState = .loaded
    state.selectedOptionID = 31
    state.hasPublishedPerspective = false
    state.submitRequestID = requestID
    let store = TestStore(initialState: state) { ClassBattleFlowFeature() } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(
        spy: spy,
        session: serverSession,
        history: history
      )
      $0.audioPlayer = ClassBattleFlowAudioPlayer(spy: spy)
    }

    #expect(!store.state.canSubmit)
    await store.send(.view(.onDisappear)) {
      $0.submitRequestID = nil
      $0.viewState = .loading
      $0.hasPublishedPerspective = nil
    }
    await store.send(.inner(.submissionResponse(requestID, .postVote, .success(true))))
    #expect(!store.state.canSubmit)
    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    #expect(!store.state.canSubmit)
    await store.receive(\.inner, .progressResponse(
      requestID,
      .success(.init(session: serverSession, voteHistory: history))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.voteHistory = history
      $0.selectedOptionID = nil
    }
    await store.finish()
    #expect(await spy.classIDs == [ClassRoom.mocks[0].id])
    #expect(await spy.voteHistoryClassIDs == [ClassRoom.mocks[0].id])
  }

  @Test
  func 클래스_배틀_로드는_서버_세션과_시나리오의_HTTP_오디오를_사용한다() async throws {
    let room = ClassRoom.mocks[0]
    let session = session(step: .preVote, commentRequired: true)
    let history = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: nil,
      status: .preVote,
      opinionChanged: nil
    )
    let spy = ClassBattleFlowSpy()
    let player = ClassBattleFlowAudioPlayer(spy: spy)
    let store = TestStore(initialState: battleState(room: room)) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(spy: spy, session: session, history: history)
      $0.battleUseCase = ClassBattleFlowScenarioStub(spy: spy)
      $0.audioPlayer = player
    }

    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    await store.receive(\.inner, .progressResponse(
      requestID,
      .success(.init(session: session, voteHistory: history))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
      $0.session = session
      $0.voteHistory = history
      $0.selectedOptionID = 31
      $0.audioRequestID = requestID
    }
    let audioURL = try #require(URL(string: "https://example.com/class-battle.mp3"))
    await store.receive(\.inner, .audioURLResponse(requestID, .success(audioURL)))
    await store.receive(\.inner, .audioLoaded(requestID, false, 0)) {
      $0.audioRequestID = nil
      $0.errorMessage = "오디오를 재생할 수 없어요. 다시 시도해 주세요."
    }
    await store.send(.view(.retryAudioTapped)) {
      $0.audioRequestID = requestID
      $0.errorMessage = nil
    }
    await store.receive(\.inner, .audioURLResponse(requestID, .success(audioURL)))
    await store.receive(\.inner, .audioLoaded(requestID, false, 0)) {
      $0.audioRequestID = nil
      $0.errorMessage = "오디오를 재생할 수 없어요. 다시 시도해 주세요."
    }
    await store.finish()
    #expect(await spy.classIDs == [room.id])
    #expect(await spy.voteHistoryClassIDs == [room.id])
    #expect(await spy.scenarioBattleIDs == [session.battle.id, session.battle.id])
    #expect(await spy.loadedURLs == [audioURL, audioURL])
  }

  @Test
  func 재진입하면_중단된_진행조회와_오디오_시간_관찰을_재개한다() async {
    let spy = ClassBattleFlowSpy()
    let player = ClassBattleFlowAudioPlayer(spy: spy)
    let loadedSession = session(step: .none, commentRequired: true)
    var state = battleState(room: .mocks[0])
    state.session = loadedSession
    state.viewState = .loading
    let store = TestStore(initialState: state) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(spy: spy, session: loadedSession)
      $0.audioPlayer = player
    }

    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    await store.receive(\.inner, .progressResponse(
      requestID,
      .success(.init(session: loadedSession, voteHistory: nil))
    )) {
      $0.loadRequestID = nil
      $0.viewState = .loaded
    }
    await store.finish()
    #expect(await spy.classIDs == [ClassRoom.mocks[0].id])

    var audioState = battleState(room: .mocks[0])
    audioState.session = session(step: .preVote, commentRequired: true)
    audioState.viewState = .loaded
    audioState.isAudioReady = true
    audioState.isPlaying = true
    audioState.isLoadingPerspectives = true
    let audioStore = TestStore(initialState: audioState) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.audioPlayer = player
    }
    await audioStore.send(.view(.onDisappear)) {
      $0.isPlaying = false
      $0.isLoadingPerspectives = false
    }
    await audioStore.send(.view(.onAppear))
    await audioStore.finish()
    #expect(await spy.timeSubscriptions == 1)
  }

  @Test
  func 다시듣기_중에도_진행률과_종료상태를_갱신한다() async {
    var state = battleState(room: .mocks[0])
    state.session = session(step: .preVote, commentRequired: true)
    state.viewState = .loaded
    state.isAudioReady = true
    state.audioDuration = 30
    state.hasListened = true
    state.isPlaying = true
    let store = TestStore(initialState: state) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.audioPlayer = ClassBattleFlowAudioPlayer(spy: ClassBattleFlowSpy())
    }

    await store.send(.inner(.playerTimeUpdated(requestID, 15))) {
      $0.currentTime = 15
    }
    await store.send(.inner(.playerTimeUpdated(requestID, 30))) {
      $0.currentTime = 30
      $0.isPlaying = false
    }
    await store.finish()
  }

  @Test
  func 의견_페이지_요청_취소_후_더보기를_다시_시도할_수_있다() async {
    var state = battleState(room: .mocks[0])
    state.session = session(step: .completed, commentRequired: false)
    state.viewState = .loaded
    state.hasMorePerspectives = true
    state.nextPerspectiveCursor = "next-page"
    state.isLoadingPerspectives = true
    state.perspectiveRequestID = requestID
    let store = TestStore(initialState: state) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(spy: ClassBattleFlowSpy())
      $0.audioPlayer = ClassBattleFlowAudioPlayer(spy: ClassBattleFlowSpy())
    }

    await store.send(.view(.onDisappear)) {
      $0.perspectiveRequestID = nil
      $0.isLoadingPerspectives = false
    }
    await store.send(.view(.loadMorePerspectivesTapped)) {
      $0.perspectiveRequestID = requestID
      $0.isLoadingPerspectives = true
    }
    await store.receive(\.inner, .perspectivePageResponse(requestID, .failure(.invalidResponse))) {
      $0.perspectiveRequestID = nil
      $0.isLoadingPerspectives = false
      $0.perspectiveErrorMessage = ClassBattleError.invalidResponse.message
    }
    await store.finish()
  }

  @Test
  func 화면_이탈로_좋아요_요청이_취소되어도_다시_좋아요를_누를_수_있다() async {
    let nextRequestID = UUID(uuidString: "00000000-0000-0000-0000-000000000043")!
    var state = battleState(room: .mocks[0])
    state.session = session(step: .completed, commentRequired: false)
    state.viewState = .loaded
    state.perspectiveLikeRequestID = requestID
    state.voteStats = .init(options: [], totalCount: 0, updatedAt: .now)
    state.hasPublishedPerspective = false
    state.perspectives = [ClassPerspectiveItem(
      id: 77,
      author: .init(userTag: "member", nickname: "참가자", characterType: nil, characterImageURL: nil),
      option: .init(id: 1, label: "A", title: "찬성", stance: "찬성"),
      content: "내 생각",
      likeCount: 4,
      commentCount: 0,
      isLiked: false,
      isMyPerspective: false,
      status: nil,
      createdAt: .now
    )]
    let serverItem = ClassPerspectiveItem(
      id: 77,
      author: state.perspectives[0].author,
      option: state.perspectives[0].option,
      content: state.perspectives[0].content,
      likeCount: 5,
      commentCount: 0,
      isLiked: true,
      isMyPerspective: false,
      status: nil,
      createdAt: state.perspectives[0].createdAt
    )
    let page = ClassPerspectivePage(items: [serverItem], nextCursor: nil, hasNext: false)
    let store = TestStore(initialState: state) { ClassBattleFlowFeature() } withDependencies: {
      $0.uuid = .constant(nextRequestID)
      $0.audioPlayer = ClassBattleFlowAudioPlayer(spy: ClassBattleFlowSpy())
      $0.perspectiveUseCase = MockPerspectiveRepository()
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(spy: ClassBattleFlowSpy(), perspectivesPage: page)
    }

    await store.send(.view(.onDisappear)) {
      $0.perspectiveLikeRequestID = nil
      $0.perspectives = []
    }
    await store.send(.inner(.perspectiveLikeResponse(requestID, 77, true, .success(true))))
    await store.send(.view(.perspectiveLikeTapped(77)))
    await store.send(.view(.onAppear)) {
      $0.perspectiveRequestID = nextRequestID
      $0.isLoadingPerspectives = true
    }
    await store.receive(\.inner, .perspectivePageResponse(nextRequestID, .success(page))) {
      $0.perspectiveRequestID = nil
      $0.isLoadingPerspectives = false
      $0.perspectives = [serverItem]
    }
    await store.send(.view(.perspectiveLikeTapped(77))) {
      $0.perspectiveLikeRequestID = nextRequestID
    }
    await store.receive(\.inner, .perspectiveLikeResponse(nextRequestID, 77, false, .success(true))) {
      $0.perspectiveLikeRequestID = nil
      let item = $0.perspectives[0]
      $0.perspectives[0] = ClassPerspectiveItem(
        id: item.id,
        author: item.author,
        option: item.option,
        content: item.content,
        likeCount: 4,
        commentCount: item.commentCount,
        isLiked: false,
        isMyPerspective: item.isMyPerspective,
        status: item.status,
        createdAt: item.createdAt
      )
    }
    await store.finish()
  }

  @Test
  func 클래스_API_실패는_오류_화면에_표시한다() async {
    let spy = ClassBattleFlowSpy()
    let store = TestStore(initialState: battleState(room: .mocks[0])) {
      ClassBattleFlowFeature()
    } withDependencies: {
      $0.uuid = .constant(requestID)
      $0.classBattleUseCase = ClassBattleFlowUseCaseStub(spy: spy, failsLoad: true)
    }

    await store.send(.view(.onAppear)) { $0.loadRequestID = requestID }
    await store.receive(\.inner, .progressResponse(requestID, .failure(.network("API 연결 실패")))) {
      $0.loadRequestID = nil
      $0.viewState = .error
      $0.errorMessage = "API 연결 실패"
    }
    await store.finish()
    #expect(await spy.classIDs == [ClassRoom.mocks[0].id])
    #expect(await spy.scenarioBattleIDs.isEmpty)
  }

  @Test
  func 사전투표_후에는_오디오를_듣고_완료할_수_있다() {
    var state = battleState(room: .mocks[0])
    state.viewState = .loaded
    state.session = session(step: .preVote, commentRequired: true)
    state.voteHistory = ClassVoteHistory(
      battleTitle: "토론",
      preVote: ClassVoteChoice(optionID: 31, label: "A", title: "찬성"),
      postVote: nil,
      status: .preVote,
      opinionChanged: nil
    )
    state.selectedOptionID = 31

    #expect(state.isAudioStep)
    #expect(state.buttonTitle == "청취 완료")
    #expect(!state.canSubmit)

    state.hasListened = true
    #expect(state.canSubmit)

    state.selectedOptionID = 32
    state.hasListened = false
    #expect(state.buttonTitle == "사전투표 변경하기")
    #expect(state.canSubmit)
  }

  @Test
  func 의견이_필수가_아니어도_최종투표_후_의견을_쓸_수_있다() {
    var state = battleState(room: .mocks[0])
    state.viewState = .loaded
    state.session = session(step: .completed, commentRequired: false)
    state.hasPublishedPerspective = false

    #expect(state.shouldShowComposer)
    #expect(!state.canSubmit)
    state.draft = "제 생각은 달라요."
    #expect(state.canSubmit)
    #expect(state.buttonTitle == "의견 등록하기")
  }

  @Test
  func 투표_변경_라벨은_투표_이력의_판정에_따른다() {
    var state = battleState(room: .mocks[0])
    #expect(state.opinionChangeLabel == nil)

    state.voteHistory = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: .init(optionID: 32, label: "B", title: "반대"),
      status: .completed,
      opinionChanged: true
    )
    #expect(state.opinionChangeLabel == "생각이 바뀌었어요")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: .init(optionID: 31, label: "A", title: "찬성"),
      status: .completed,
      opinionChanged: false
    )
    #expect(state.opinionChangeLabel == "처음 생각을 유지했어요")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: .init(optionID: 32, label: "B", title: "반대"),
      status: .completed,
      opinionChanged: nil
    )
    #expect(state.opinionChangeLabel == "생각이 바뀌었어요")

    state.voteHistory = ClassVoteHistory(
      battleTitle: "토론",
      preVote: .init(optionID: 31, label: "A", title: "찬성"),
      postVote: .init(optionID: 31, label: "A", title: "찬성"),
      status: .completed,
      opinionChanged: nil
    )
    #expect(state.opinionChangeLabel == "처음 생각을 유지했어요")
  }

  @Test
  func 의견_제출_실패는_입력창을_유지하고_수정하면_오류를_지운다() async {
    var state = battleState(room: .mocks[0])
    state.viewState = .loaded
    state.session = session(step: .completed, commentRequired: false)
    state.hasPublishedPerspective = false
    state.draft = "제 생각"
    state.submitRequestID = requestID
    let store = TestStore(initialState: state) { ClassBattleFlowFeature() }
    let error = ClassBattleError.network("등록 실패")

    await store.send(.inner(.submissionResponse(requestID, .completed, .failure(error)))) {
      $0.submitRequestID = nil
      $0.errorMessage = error.message
    }
    #expect(store.state.shouldShowComposer)
    #expect(store.state.draft == "제 생각")

    await store.send(.view(.draftChanged("수정한 생각"))) {
      $0.draft = "수정한 생각"
      $0.errorMessage = nil
    }
    await store.finish()
  }

  private func session(
    step: ClassBattleStep,
    commentRequired: Bool
  ) -> ClassBattleSession {
    ClassBattleSession(
      classID: 1,
      myRole: .member,
      closeAt: Date(timeIntervalSince1970: 1_800_000_000),
      closed: false,
      commentRequired: commentRequired,
      canParticipate: true,
      participationCompleted: false,
      battle: ClassBattleDetail(
        id: 10,
        title: "토론",
        summary: "요약",
        thumbnailURL: nil,
        description: "설명",
        shareURL: nil,
        userVoteStatus: nil,
        currentStep: step,
        participantsCount: 1,
        audioDuration: 30,
        options: []
      )
    )
  }

  private func battleState(room: ClassRoom) -> ClassBattleFlowFeature.State {
    var state = ClassBattleFlowFeature.State()
    state.instanceID = requestID
    state.room = room
    return state
  }
}

private actor ClassBattleFlowSpy {
  private(set) var classIDs: [Int] = []
  private(set) var voteHistoryClassIDs: [Int] = []
  private(set) var scenarioBattleIDs: [Int] = []
  private(set) var loadedURLs: [URL] = []
  private(set) var timeSubscriptions = 0

  func recordClass(_ id: Int) { classIDs.append(id) }
  func recordVoteHistory(_ id: Int) { voteHistoryClassIDs.append(id) }
  func recordScenario(_ id: Int) { scenarioBattleIDs.append(id) }
  func recordAudio(_ url: URL) { loadedURLs.append(url) }
  func recordTimeSubscription() { timeSubscriptions += 1 }
}

private struct ClassBattleFlowUseCaseStub: ClassBattleInterface {
  let spy: ClassBattleFlowSpy
  var session: ClassBattleSession?
  var history: ClassVoteHistory?
  var perspectivesPage: ClassPerspectivePage?
  var failsLoad = false

  func fetchBattle(classID: Int) async throws -> ClassBattleSession {
    await spy.recordClass(classID)
    if failsLoad { throw ClassBattleError.network("API 연결 실패") }
    guard let session else { throw ClassBattleError.invalidResponse }
    return session
  }

  func fetchMyVotes(classID: Int) async throws -> ClassVoteHistory {
    await spy.recordVoteHistory(classID)
    guard let history else { throw ClassBattleError.voteNotFound }
    return history
  }

  func submitPreVote(classID _: Int, optionID _: Int) async throws -> ClassVoteReceipt { throw ClassBattleError.invalidResponse }
  func completeTTS(classID _: Int) async throws { throw ClassBattleError.invalidResponse }
  func submitPostVote(classID _: Int, optionID _: Int) async throws -> ClassVoteReceipt { throw ClassBattleError.invalidResponse }
  func fetchVoteStats(classID _: Int) async throws -> ClassVoteStats { throw ClassBattleError.invalidResponse }
  func publishPerspective(classID _: Int, content _: String) async throws -> ClassPerspectiveReceipt { throw ClassBattleError.invalidResponse }
  func fetchPerspectives(
    classID _: Int,
    cursor _: String?,
    size _: Int?,
    optionID _: Int?,
    sort _: String?
  ) async throws -> ClassPerspectivePage {
    guard let perspectivesPage else { throw ClassBattleError.invalidResponse }
    return perspectivesPage
  }
  func fetchMyPerspectives(classID _: Int) async throws -> [ClassPerspectiveItem] { throw ClassBattleError.invalidResponse }
}

private struct ClassBattleFlowScenarioStub: BattleInterface {
  let spy: ClassBattleFlowSpy
  private let fallback = MockBattleRepository()

  func fetchScenario(battleId: Int) async throws -> BattleScenario {
    await spy.recordScenario(battleId)
    return BattleScenario(
      battleId: battleId,
      title: "서버 시나리오",
      philosophers: [],
      isInteractive: false,
      startNodeId: 1,
      recommendedPathKey: .common,
      audios: ["COMMON": "https://example.com/class-battle.mp3"],
      nodes: []
    )
  }

  func fetchTodayBattles() async throws -> TodayBattlePage { try await fallback.fetchTodayBattles() }
  func fetchBattle(battleId: Int) async throws -> BattleDetail { try await fallback.fetchBattle(battleId: battleId) }
  func submitPreVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult { try await fallback.submitPreVote(battleId: battleId, optionId: optionId) }
  func submitPostVote(
    battleId: Int,
    optionId: Int
  ) async throws -> PreVoteResult { try await fallback.submitPostVote(battleId: battleId, optionId: optionId) }
  func fetchVoteStats(battleId: Int) async throws -> BattleVoteStats { try await fallback.fetchVoteStats(battleId: battleId) }
  func fetchPerspectives(
    battleId: Int,
    cursor: String?,
    size: Int?,
    optionId: Int?,
    sort: BattlePerspectiveSort?
  ) async throws -> BattlePerspectivePage {
    try await fallback.fetchPerspectives(battleId: battleId, cursor: cursor, size: size, optionId: optionId, sort: sort)
  }
  func createPerspective(
    battleId: Int,
    content: String,
    optionId: Int?
  ) async throws -> BattlePerspective? {
    try await fallback.createPerspective(battleId: battleId, content: content, optionId: optionId)
  }
  func fetchMyPerspective(battleId: Int) async throws -> BattlePerspective? {
    try await fallback.fetchMyPerspective(battleId: battleId)
  }
  func fetchRecommendedBattles(battleId: Int) async throws -> RecommendedBattlePage {
    try await fallback.fetchRecommendedBattles(battleId: battleId)
  }
  func proposeBattle(_ draft: BattleProposalDraft) async throws -> BattleProposal {
    try await fallback.proposeBattle(draft)
  }
}

private struct ClassBattleFlowAudioPlayer: AudioPlayerInterface {
  let spy: ClassBattleFlowSpy

  func load(url: URL) async -> Bool {
    await spy.recordAudio(url)
    return false
  }
  func play() async {}
  func pause() async {}
  func setPlaybackRate(_: Float) async {}
  func seek(to _: TimeInterval) async {}
  func duration() async -> TimeInterval { 0 }
  func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      Task {
        await spy.recordTimeSubscription()
        continuation.finish()
      }
    }
  }
}
