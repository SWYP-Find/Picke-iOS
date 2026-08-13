//
//  SettingDictionary.swift
//  ProjectTemplatePlugin
//
//  Created by 서원지 on 6/12/24.
//

import Foundation
import ProjectDescription

public extension SettingsDictionary {
  func setProductBundleIdentifier(_ value: String = "com.iOS$(BUNDLE_ID_SUFFIX)") -> SettingsDictionary {
    return merging(["PRODUCT_BUNDLE_IDENTIFIER": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setProductName(_ value: String) -> SettingsDictionary {
    return merging(["PRODUCT_NAME": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setCFBundleDisplayName(_ value: String) -> SettingsDictionary {
    return merging(["CFBundleDisplayName": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setMarketingVersion(_ value: String) -> SettingsDictionary {
    return merging(["MARKETING_VERSION": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setASAuthenticationServicesEnabled(_ value: String = "YES") -> SettingsDictionary {
    return merging(["AS_AUTHENTICATION_SERVICES_ENABLED": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setPushNotificationsEnabled(_ value: String = "YES") -> SettingsDictionary {
    return merging(["PUSH_NOTIFICATIONS_ENABLED": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setEnableBackgroundModes(_ value: String = "YES",
                                backgroundModes: String = "remote-notification") -> SettingsDictionary
  {
    return merging([
      "ENABLE_BACKGROUND_MODES": SettingValue(stringLiteral: value),
      "BACKGROUND_MODES": SettingValue(stringLiteral: backgroundModes),
    ]) { _, new in new }
  }

  func setArchs(_ value: String = "$(ARCHS_STANDARD)") -> SettingsDictionary {
    return merging(["ARCHS": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setOtherLdFlags(_ value: String = "$(inherited) -ObjC") -> SettingsDictionary {
    return merging(["OTHER_LDFLAGS": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setCurrentProjectVersion(_ value: String) -> SettingsDictionary {
    return merging(["CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setCodeSignIdentity(_ value: String = "Apple Development") -> SettingsDictionary {
    return merging(["CODE_SIGN_IDENTITY": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setCodeSignStyle(_ value: String = "Manual") -> SettingsDictionary {
    return merging(["CODE_SIGN_STYLE": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setVersioningSystem(_ value: String = "apple-generic") -> SettingsDictionary {
    return merging(["VERSIONING_SYSTEM": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setDebugInformationFormat(_ value: String = "DWARF with dSYM File") -> SettingsDictionary {
    return merging(["DEBUG_INFORMATION_FORMAT": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setStripStyle(_ value: String = "non-global") -> SettingsDictionary {
    return merging(["STRIP_STYLE": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setProvisioningProfileSpecifier(_ value: String) -> SettingsDictionary {
    return merging(["PROVISIONING_PROFILE_SPECIFIER": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setSwiftVersion(_ value: String) -> SettingsDictionary {
    return merging(["SWIFT_VERSION": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setDevelopmentTeam(_ value: String) -> SettingsDictionary {
    return merging(["DEVELOPMENT_TEAM": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setSkipInstall(_ value: Bool = false) -> SettingsDictionary {
    return merging(["SKIP_INSTALL": SettingValue(stringLiteral: value ? "YES" : "NO")])
  }

  func setExplicitlyBuiltModules(_ value: Bool = true) -> SettingsDictionary {
    return merging(["EXPLICITLY_BUILT_MODULES": SettingValue(stringLiteral: value ? "YES" : "NO")])
  }

  /// 기본 로케일을 한국어(ko)로 설정하는 메서드
  func setCFBundleDevelopmentRegion(_ value: String = "ko") -> SettingsDictionary {
    return merging(["CFBundleDevelopmentRegion": SettingValue(stringLiteral: value)]) { _, new in new }
  }

  func setAllowNonModularIncludesInFrameworkModules(_ value: Bool) -> SettingsDictionary {
    let stringValue = value ? "YES" : "NO"
    return merging([
      "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES": SettingValue(stringLiteral: stringValue),
    ]) { _, new in new }
  }
}
