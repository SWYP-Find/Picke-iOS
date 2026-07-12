//
//  Project+Settings.swift
//  MyPlugin
//
//  Created by 서원지 on 1/6/24.
//

import Foundation
import ProjectDescription

extension Settings {
  private static func commonSettings(
    appName: String,
    displayName: String,
    provisioningProfile: String,
    setSkipInstall: Bool
  ) -> SettingsDictionary {
    return SettingsDictionary()
      .setProductName(appName)
      .setCFBundleDisplayName(displayName)
      // GAD 클래스가 든 binary xcframework(GoogleMobileAds)는 래퍼(GoogleMobileAdsTarget)만
      // 링크될 뿐 최종 실행파일에 -framework 로 전파되지 않아, 명시적으로 링크해 심볼을 끌어온다.
      // -ObjC 가 링크라인의 정적 아카이브에서 ObjC 클래스를 로드하므로 -all_load 는 불필요.
      // (-all_load 를 쓰면 동적 프레임워크 Sentry/Moya/CA 심볼이 앱 바이너리에 이중 등록되어
      //  "Class ... implemented in both" 경고 + 런타임 abort 발생)
      // SDWebImage 의 category-only 파일(NSData+ImageContentType 의 sd_imageFormatForImageData:)은
      // debug-dylib 분리 링크에서 -ObjC 만으로 누락될 수 있어, SDWebImage 정적 프레임워크만
      // -force_load 로 강제 로드한다(타깃 한정이라 동적 프레임워크 중복-클래스 문제 없음).
      .setOtherLdFlags(
        "-ObjC -framework GoogleMobileAds -force_load $(BUILT_PRODUCTS_DIR)/SDWebImage.framework/SDWebImage"
      )
      .setDebugInformationFormat("dwarf-with-dsym")
      .setProvisioningProfileSpecifier(provisioningProfile)
      .setSkipInstall(setSkipInstall)
      .setCFBundleDevelopmentRegion("ko")
  }

  private static func commonBaseSettings(
    appName: String
  ) -> SettingsDictionary {
    return SettingsDictionary()
      .setProductName(appName)
      .setOtherLdFlags()
      .setStripStyle()
  }

  public static let appMainSetting: Settings = .settings(
    base: SettingsDictionary()
      .setProductName(Project.Environment.appName)
      .setCFBundleDisplayName(Project.Environment.appName)
      .setMarketingVersion(.appVersion())
      .setEnableBackgroundModes()
      .setArchs()
      .setOtherLdFlags()
      .setCurrentProjectVersion(.appBuildVersion())
      .setCodeSignIdentity()
      .setCodeSignStyle()
      .setSwiftVersion("6.0")
      .setVersioningSystem()
      .setProvisioningProfileSpecifier("match Development \(Project.Environment.bundlePrefix)")
      .setDevelopmentTeam(Project.Environment.organizationTeamId)
      .setCFBundleDevelopmentRegion()
      .setDebugInformationFormat(),
    configurations: [
      // Stage 는 debug 타입 컨피그(기존 Debug/Dev 컨피그를 대체).
      .debug(
        name: .stage,
        settings:
        commonSettings(
          appName: Project.Environment.appStageName,
          displayName: Project.Environment.appName,
          provisioningProfile: "match AppStore \(Project.Environment.bundlePrefix)",
          setSkipInstall: false
        ),
        xcconfig: .path(.stage)
      ),
      .release(
        name: .release,
        settings:
        commonSettings(
          appName: Project.Environment.appName,
          displayName: Project.Environment.appName,
          provisioningProfile: "match AppStore \(Project.Environment.bundlePrefix)",
          setSkipInstall: false
        ),
        xcconfig: .path(.release)
      ),
      .release(
        name: .prod,
        settings:
        commonSettings(
          appName: Project.Environment.appProdName,
          displayName: Project.Environment.appName,
          provisioningProfile: "match AppStore \(Project.Environment.bundlePrefix)",
          setSkipInstall: false
        ),
        xcconfig: .path(.prod)
      ),

    ], defaultSettings: .recommended
  )

  public static func appBaseSetting(appName: String) -> Settings {
    let appBaseSetting: Settings = .settings(
      base: SettingsDictionary()
        .setProductName(appName)
        .setMarketingVersion(.appVersion())
        .setCurrentProjectVersion(.appBuildVersion())
        .setCodeSignIdentity()
        .setArchs()
        .setSwiftVersion("6.0")
        .setVersioningSystem()
        .setDebugInformationFormat(),
      configurations: [
        .debug(
          name: .stage,
          settings:
          commonBaseSettings(
            appName: appName
          ),
          xcconfig:
          .relativeToRoot("./Config/Stage.xcconfig")
        ),
        .release(
          name: .release,
          settings: commonBaseSettings(
            appName: appName
          ),
          xcconfig: .relativeToRoot("./Config/Release.xcconfig")
        ),
      ], defaultSettings: .recommended
    )

    return appBaseSetting
  }
}
