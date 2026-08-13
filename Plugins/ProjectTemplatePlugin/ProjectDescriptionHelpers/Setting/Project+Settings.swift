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
      // SDWebImage 는 동적 프레임워크로 링크/임베드되므로 force_load 하지 않는다.
      .setOtherLdFlags("-ObjC -framework GoogleMobileAds")
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
          provisioningProfile: "match Development \(Project.Environment.bundlePrefix)",
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

      // Tuist 의 recommended 기본값은 타겟 레벨에 CODE_SIGN_IDENTITY = "iPhone Developer" 를 주입해
      // base 설정을 덮는다. match 가 발급하는 건 Apple Development 이므로 이 키만 제외한다.
    ], defaultSettings: .recommended(excluding: ["CODE_SIGN_IDENTITY"])
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
