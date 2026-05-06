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
      .setCFBundleDisplayName("$(BUNDLE_DISPLAY_NAME)")  // 🎯 xconfig에서 설정
      .setCFBundlePackageType("APPL")
      .setCFBundleShortVersionString(.appVersion())
      .setAppTransportSecurity()
      .setCFBundleURLTypes()
      .setAppUseExemptEncryption(value: false)
      .setCFBundleVersion(.appBuildVersion())
      .setLSRequiresIPhoneOS(true)
      .setUIAppFonts(["PretendardVariable.ttf"])
      .setUIApplicationSceneManifest([
        "UIApplicationSupportsMultipleScenes": true,
        "UISceneConfigurations": [
          "UIWindowSceneSessionRoleApplication": [
            [
              "UISceneConfigurationName": "Default Configuration",
            ]
          ]
        ]
      ])
      .setUIRequiredDeviceCapabilities(["armv7"])
      .setCFBundleDevelopmentRegion()
      .setUISupportedInterfaceOrientations(["UIInterfaceOrientationPortrait"])
      .setBaseURL("$(BASE_URL)")
      .setGoogleClientID("${GOOGLE_CLIENT_ID}")
      .setGoogleClientiOSID("${GOOGLE_IOS_CLIENT_ID}")
      .setMixpanelToken("$(MIXPANEL_TOKEN)")
      .setGIDClientID("${GOOGLE_CLIENT_ID}")
      .setAdmobToken("${ADMOB_TOKEN}")
      .setGADApplicationId("${ADMOB_TOKEN}")
//      .setSKAdNetworkItems([
//
//      ])
    
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
