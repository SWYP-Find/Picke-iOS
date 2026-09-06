//
//  Modules.swift
//  Plugins
//
//  레이어별 모듈 카탈로그(단일 출처).
//  모듈 추가 = case 한 줄. rawValue 가 실제 타깃명이자 디렉토리명이라 오타로 깨지지 않는다.
//

import Foundation
import ProjectDescription

public enum FeatureModule: String, CaseIterable {
  case splash = "Splash"
  case auth = "Auth"
  case home = "Home"
  case chat = "Chat"
  case hifi = "Hifi"
  case web = "Web"
  case battle = "Battle"
  case profile = "Profile"
  case notification = "Notification"

  /// Projects/Feature/<name>
  var path: Path {
    return .relativeToFeature(rawValue)
  }
}

public enum CoreModule: String, CaseIterable {
  case assembly = "CoreAssembly"
  case logger = "PickeCoreLogger"
  case storage = "PickeStorage"
  case coreUtility = "PickeCoreUtility"
  case thirdParty = "PickeThirdParty"

  /// Projects/Core/<name>
  var path: Path {
    return .relativeToCore(rawValue)
  }
}

public enum ServiceModule: String, CaseIterable {
  case assembly = "ServiceAssembly"
  case api = "API"
  case apiEndpoint = "APIEndpoint"
  case ad = "AdService"
  case analytics = "AnalyticsService"
  case audioPlayer = "AudioPlayerService"
  case device = "DeviceService"

  /// Projects/Service/<name>
  var path: Path {
    return .relativeToService(rawValue)
  }
}

public enum DomainModule: String, CaseIterable {
  case assembly = "DomainAssembly"
  case appUpdate = "AppUpdateDomain"
  case attendance = "AttendanceDomain"
  case auth = "AuthDomain"
  case battle = "BattleDomain"
  case comment = "CommentDomain"
  case home = "HomeDomain"
  case notification = "NotificationDomain"
  case perspective = "PerspectiveDomain"
  case profile = "ProfileDomain"
  case search = "SearchDomain"

  /// Projects/Domain/<name>
  var path: Path {
    return .relativeToDomain(rawValue)
  }
}

public enum DataModule: String, CaseIterable {
  case model = "Model"

  /// Projects/Data/<name>
  var path: Path {
    return .relativeToData(rawValue)
  }
}

// MARK: - 아직 레이어 카탈로그로 접히지 않은 모듈

/// Network 레이어. Core/PickeNetwork 단일 모듈로 합치기 전까지만 남는다.
public enum ModulePath {
  case network(Networks)
}

public extension ModulePath {
  enum Networks: String, CaseIterable {
    case networkModule = "NetworkModule"
    case networking = "Networking"
    case networkToken = "NetworkToken"
    case networkHeader = "NetworkHeader"
    case thirdPartys = "ThirdPartys"

    public static let name: String = "Network"
  }
}
