//
//  DiRegister.swift
//  Picke
//
//  Created by Wonji Suh  on 11/24/25.
//

import Foundation

import DomainInterface
import Foundations
import Repository
import UseCase

import ComposableArchitecture
import WeaveDI

/// 기본 WeaveDI 관리자 (단순하고 안정적)
@MainActor
public final class AppDIManager: Sendable {
  public static let shared = AppDIManager()

  private init() {}

  /// 기본 WeaveDI 의존성 등록 (Repository만)
  public func registerDefaultDependencies() {
    // Repository 구현체들만 등록
    WeaveDI.builder
      // 🔧 인프라 계층 (PFW 단순성 원칙)
      .register { KeychainManager() as KeychainManaging }
      .register {
        let keychainManager = UnifiedDI.resolve(KeychainManaging.self) ?? KeychainManager()
        return KeychainTokenProvider(keychainManager: keychainManager) as TokenProviding
      }

      // 🏗️ Repository 계층 (Clean Architecture + PFW)
      .register { AuthRepositoryImpl() as AuthInterface }
      .register { HomeRepositoryImpl() as HomeInterface }
      .register { BattleRepositoryImpl() as BattleInterface }
      .register { AudioPlayerRepositoryImpl() as AudioPlayerInterface }
//      .register { ProfileRepositoryImpl() as ProfileInterface }
//      .register { AppUpdateRepositoryImpl() as AppUpdateInterface }

      // 🔐 OAuth Provider 계층 (PFW 조합 패턴)
      .register {
        MainActor.assumeIsolated {
          GoogleOAuthRepositoryImpl(presentationContextProvider: AppPresentationContextProvider(
          )) as GoogleOAuthInterface
        }
      }
      .register { AppleLoginRepositoryImpl() as AppleAuthRequestInterface }
      .register {
        MainActor.assumeIsolated {
          KakaoOAuthRepository(presentationContextProvider: AppPresentationContextProvider()) as KakaoOAuthInterface
        }
      }
      .register { AppleOAuthRepositoryImpl() as AppleOAuthInterface }
      .register { AppleOAuthProvider() as AppleOAuthProviderInterface }
      .register { GoogleOAuthProvider() as GoogleOAuthProviderInterface }
      .register { KakaoOAuthProvider() as KakaoOAuthProviderInterface }
      // 📝 비즈니스 로직 계층 (PFW 단일 책임)
//      .register { OnBoardingRepositoryImpl() as OnBoardingInterface }
//      .register { SignUpRepositoryImpl() as SignUpInterface }
//      .register { AttendanceRepositoryImpl() as AttendanceInterface }
//      .register { MyPageRepositoryImpl() as MyPageRepositoryInterface }
//      .register { ScheduleRepositoryImpl() as ScheduleInterface }
//      .register { QRCodeRepositoryImpl() as QRCodeInterface }
      .configure()
  }
}
