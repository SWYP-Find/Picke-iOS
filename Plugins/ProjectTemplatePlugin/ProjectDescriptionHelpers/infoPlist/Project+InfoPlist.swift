//
//  Project+InfoPlist.swift
//  Plugins
//
//  Created by Wonji Suh  on 3/22/25.
//

import Foundation
import ProjectDescription

public extension InfoPlist {
  static let appInfoPlist: Self = .extendingDefault(
    with: InfoPlistDictionary()
      .setUIUserInterfaceStyle("Light")
      .setUILaunchScreens()
      .setCFBundleDevelopmentRegion()
      .setCFBundleDevelopmentRegion("$(DEVELOPMENT_LANGUAGE)")
      .setCFBundleExecutable("$(EXECUTABLE_NAME)")
      .setCFBundleIdentifier("$(PRODUCT_BUNDLE_IDENTIFIER)")
      .setCFBundleInfoDictionaryVersion("6.0")
      .setCFBundleName("$(PRODUCT_NAME)")
      .setCFBundleDisplayName("$(BUNDLE_DISPLAY_NAME)") // 🎯 xconfig에서 설정
      .setCFBundlePackageType("APPL")
      .setCFBundleShortVersionString(.appVersion())
      .setAppTransportSecurity()
      .setCFBundleURLTypes()
      .setAppUseExemptEncryption(value: false)
      .setCFBundleVersion(.appBuildVersion())
      .setLSRequiresIPhoneOS(true)
      .setUIApplicationSceneManifest([
        "UIApplicationSupportsMultipleScenes": true,
        "UISceneConfigurations": [
          "UIWindowSceneSessionRoleApplication": [
            [
              "UISceneConfigurationName": "Default Configuration",
            ],
          ],
        ],
      ])
      .setUIRequiredDeviceCapabilities(["armv7"])
      .setCFBundleDevelopmentRegion()
      .setUISupportedInterfaceOrientations(["UIInterfaceOrientationPortrait"])
      .setBaseURL("$(BASE_URL)")
      .setGoogleClientID("${GOOGLE_CLIENT_ID}")
      .setGoogleClientiOSID("${GOOGLE_IOS_CLIENT_ID}")
      .setMixpanelToken("$(MIXPANEL_TOKEN)")
      .setSentryDSN("$(SENTRY_DSN)")
      .setSentryEnvironment("$(SENTRY_ENVIRONMENT)")
      .setGIDClientID("${GOOGLE_CLIENT_ID}")
      .setAdmobToken("${ADMOB_TOKEN}")
      .setGADApplicationId("${ADMOB_TOKEN}")
      .setRewardAdUnit("$(REWARD_AD_UNIT)")
      .setAdFitBannerClientIds(
        size320x50: "$(ADFIT_BANNER_320X50)",
        size320x100: "$(ADFIT_BANNER_320X100)",
        size320x480: "$(ADFIT_BANNER_320X480)"
      )
      .setAdFitNativeClientIds(
        square: "$(ADFIT_NATIVE_1_1)",
        wide: "$(ADFIT_NATIVE_2_1)"
      )
      .setAdFitAppTransitionId("$(ADFIT_APP_TRANSITION)")
      .setUserTrackingUsageDescription(
        "맞춤형 광고를 추천하기 위해 기기의 광고 식별자를 사용합니다."
      )
      // 광고 네트워크 SKAdNetwork 식별자. 미등록 시 iOS 14+ 에서 해당 네트워크의
      // SKAdNetwork 기반 광고가 집행되지 않아 노출/수익이 줄어든다.
      // 아래는 카카오 AdFit + Google AdMob(공식 3P 네트워크 목록) 을 병합한 것으로, 중복은 제거했다.
      // AdMob 목록 출처: https://developers.google.com/admob/ios/3p-skadnetworks
      .setSKAdNetworkItems([
        // 카카오 AdFit
        "9t245vhmpl.skadnetwork",
        "v72qych5uu.skadnetwork",
        "x8uqf25wch.skadnetwork",
        "8s468mfl3y.skadnetwork",
        "54NZKQM89Y.skadnetwork",
        "t6d3zquu66.skadnetwork",
        // Google AdMob (위와 겹치는 3개 제외)
        "cstr6suwn9.skadnetwork",
        "4fzdc2evr5.skadnetwork",
        "2fnua5tdw4.skadnetwork",
        "ydx93a7ass.skadnetwork",
        "p78axxw29g.skadnetwork",
        "ludvb6z3bs.skadnetwork",
        "cp8zw746q7.skadnetwork",
        "3sh42y64q3.skadnetwork",
        "c6k4g5qg8m.skadnetwork",
        "s39g8k73mm.skadnetwork",
        "wg4vff78zm.skadnetwork",
        "3qy4746246.skadnetwork",
        "f38h382jlk.skadnetwork",
        "hs6bdukanm.skadnetwork",
        "mlmmfzh3r3.skadnetwork",
        "v4nxqhlyqp.skadnetwork",
        "wzmmz9fp6w.skadnetwork",
        "su67r6k2v3.skadnetwork",
        "yclnxrl5pm.skadnetwork",
        "t38b2kh725.skadnetwork",
        "7ug5zh24hu.skadnetwork",
        "gta9lk7p23.skadnetwork",
        "vutu7akeur.skadnetwork",
        "y5ghdn5j9k.skadnetwork",
        "v9wttpbfk9.skadnetwork",
        "n38lu8286q.skadnetwork",
        "47vhws6wlr.skadnetwork",
        "kbd757ywx3.skadnetwork",
        "a2p9lx4jpn.skadnetwork",
        "22mmun2rn5.skadnetwork",
        "44jx6755aq.skadnetwork",
        "k674qkevps.skadnetwork",
        "4468km3ulz.skadnetwork",
        "2u9pt9hc89.skadnetwork",
        "klf5c3l5u5.skadnetwork",
        "ppxm28t8ap.skadnetwork",
        "kbmxgpxpgc.skadnetwork",
        "uw77j35x4d.skadnetwork",
        "578prtvx9j.skadnetwork",
        "4dzt52r2t5.skadnetwork",
        "tl55sbb4fm.skadnetwork",
        "c3frkrj4fj.skadnetwork",
        "e5fvkxwrpn.skadnetwork",
        "8c4e2ghe7u.skadnetwork",
        "3rd42ekr43.skadnetwork",
        "97r2b46745.skadnetwork",
        "3qcr597p9d.skadnetwork",
      ])
      .setKakaoRestApiKey()
      .setLSApplicationQueriesSchemes([
        "kakaokompassauth", // 카카오톡 로그인
        "kakaolink", // 카카오톡 공유
      ])
  )

  static let moduleInfoPlist: Self = .extendingDefault(
    with: InfoPlistDictionary()
      .setUIUserInterfaceStyle("Light")
      .setCFBundleDevelopmentRegion("$(DEVELOPMENT_LANGUAGE)")
      .setCFBundleExecutable("$(EXECUTABLE_NAME)")
      .setCFBundleIdentifier("$(PRODUCT_BUNDLE_IDENTIFIER)")
      .setCFBundleInfoDictionaryVersion("6.0")
      .setCFBundlePackageType("APPL")
      .setCFBundleShortVersionString(.appVersion())
      .setBaseURL("$(BASE_URL)")
  )
}
