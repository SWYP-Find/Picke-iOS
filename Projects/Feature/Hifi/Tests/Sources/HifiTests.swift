//
//  HifiTests.swift
//  HifiTests
//
//  Created by Picke on 10/11/26.
//

import Foundation
import Testing
import ComposableArchitecture
import AdDomainInterface
@testable import Hifi

struct HifiTests {
  @Test
  func serverAdsFollowEveryThreeItemsIncludingFirstSlot() {
    var state = HifiFeature.State()
    state.ads = [ad("first"), ad("second")]
    #expect(state.ad(after: -1) == nil)
    #expect(state.ad(after: 0) == nil)
    #expect(state.ad(after: 2)?.code == "first")
    #expect(state.ad(after: 4) == nil)
    #expect(state.ad(after: 5)?.code == "second")
    #expect(state.ad(after: 8)?.code == "first")
    #expect(state.ad(after: 11)?.code == "second")
    #expect(state.ad(after: 14)?.code == "first")
    #expect(state.ad(after: 12) == nil)
    state.ads = []
    #expect(state.ad(after: 2) == nil)
    #expect(state.ad(after: 5) == nil)
  }

  @Test @MainActor
  func fetchingAdsDoesNotRecordImpressions() async {
    let ads = [ad("first")]
    let store = TestStore(initialState: HifiFeature.State()) { HifiFeature() }
    await store.send(.inner(.adsResponse(.success(ads)))) {
      $0.ads = ads
    }
    #expect(store.state.reportedAdCodesByItemID.isEmpty)
    await store.finish()
  }

  @Test @MainActor
  func unknownAndAlreadyReportedAdsDoNotRecordAgain() async {
    var state = HifiFeature.State()
    state.ads = [ad("first")]
    state.reportedAdCodesByItemID = [6: ["first"]]
    let store = TestStore(initialState: state) { HifiFeature() }
    await store.send(.view(.adVisible(code: "unknown", itemID: 6)))
    await store.send(.view(.adVisible(code: "first", itemID: 6)))
    await store.finish()
  }

  @Test @MainActor
  func visibleAdRecordsOncePerItem() async {
    let client = ImpressionRecorder()
    var state = HifiFeature.State()
    state.ads = [ad("first")]
    let store = TestStore(initialState: state) { HifiFeature() } withDependencies: {
      $0.feedAdUseCase = client
    }
    await store.send(.view(.adVisible(code: "first", itemID: 6))) {
      $0.reportedAdCodesByItemID = [6: ["first"]]
    }
    await store.receive { action in
      guard case .inner(.impressionResponse) = action else { return false }
      return true
    }
    await store.send(.view(.adVisible(code: "first", itemID: 6)))
    await store.send(.view(.adVisible(code: "first", itemID: 12))) {
      $0.reportedAdCodesByItemID[12] = ["first"]
    }
    await store.receive { action in
      guard case .inner(.impressionResponse) = action else { return false }
      return true
    }
    let codes = await client.codes
    #expect(codes == ["first", "first"])
    await store.finish()
  }

  @Test @MainActor
  func searchFailureShowsToast() async {
    var state = HifiFeature.State()
    state.viewState = .loading
    let store = TestStore(initialState: state) { HifiFeature() }
    store.exhaustivity = .off

    await store.send(.inner(.searchResponse(
      .failure(.noData),
      reset: true,
      category: state.selectedCategory,
      sort: state.selectedSort
    )))
    #expect(store.state.toastMessage == "정보를 불러오지 못했어요")
  }

  @Test @MainActor
  func reselectingTabRequestsScrollToTop() async {
    let store = TestStore(initialState: HifiFeature.State()) { HifiFeature() }

    await store.send(.view(.exploreTabReselected)) {
      $0.scrollToTopRequest = 1
    }
  }

  private func ad(_ code: String) -> FeedAd {
    FeedAd(
      code: code,
      network: "ADPICK",
      title: "광고 제목",
      subtitle: "광고 설명",
      imageURL: URL(string: "https://example.com/image.jpg")!,
      ctaText: "구매하러 가기",
      clickURL: URL(string: "https://ad.picke.store/c/\(code)")!,
      label: "광고"
    )
  }
}

private actor ImpressionRecorder: FeedAdInterface {
  var codes: [String] = []

  func fetchAds() async throws -> [FeedAd] { [] }
  func recordImpressions(codes: [String]) async throws {
    self.codes.append(contentsOf: codes)
  }
}
