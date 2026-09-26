"""Static wiring checks only; these do not execute SwiftUI or contact ad services."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AdPlacementTests(unittest.TestCase):
    def source(self, path):
        return (ROOT / path).read_text()

    def test_home_keeps_adfit(self):
        source = self.source("Projects/Feature/Home/Sources/Main/View/HomeView.swift")
        self.assertIn("AdFitNativeAdView(", source)

    def test_explore_uses_only_existing_feed_ad_row(self):
        source = self.source("Projects/Feature/Hifi/Sources/View/HifiView.swift")
        self.assertIn("FeedAdRow(", source)
        self.assertNotIn("AdFitBannerView(", source)
        self.assertIn("send(.adVisible(code: ad.code, itemID: item.id))", source)
        self.assertIn("send(.serverAdClicked(network: ad.network))", source)

    def test_other_native_slots_use_server_ads(self):
        for path in (
            "Projects/Feature/Chat/Sources/Curation/View/CurationView.swift",
            "Projects/Feature/Profile/Sources/Main/View/ProfileView.swift",
        ):
            with self.subTest(path=path):
                source = self.source(path)
                self.assertIn("FeedNativeAdView(", source)
                self.assertNotIn("MixedNativeAdView(", source)
                self.assertIn("send(.serverAdClicked(network: $0))", source)

    def test_feed_slot_preserves_tracking_without_adfit_fallback(self):
        source = self.source("Projects/Feature/Ad/Sources/FeedNativeAdView.swift")
        self.assertIn("FeedAdRow(", source)
        self.assertIn("feedAdUseCase.fetchAds()", source)
        self.assertIn("feedAdUseCase.recordImpressions(codes: [ad.code])", source)
        self.assertIn("scenePhase == .active, !didRecordImpression", source)
        self.assertIn("guard !Task.isCancelled else { return }", source)
        self.assertNotIn("AdFit", source)
        self.assertNotIn("UserDefaults", source)


if __name__ == "__main__":
    unittest.main()
