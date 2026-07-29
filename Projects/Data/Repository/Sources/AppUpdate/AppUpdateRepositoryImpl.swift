//
//  AppUpdateRepositoryImpl.swift
//  Repository
//

import Foundation

import DomainInterface
import Entity
import Model

import LogMacro

public final class AppUpdateRepositoryImpl: AppUpdateInterface {
  private let urlSession: URLSession
  private let bundleId: String

  public init(
    urlSession: URLSession = .shared,
    bundleId: String? = nil
  ) {
    self.urlSession = urlSession
    self.bundleId = bundleId ?? Bundle.main.bundleIdentifier ?? ""
  }

  public func checkForUpdate() async throws -> AppUpdateInfo {
    guard !bundleId.isEmpty else { throw AppUpdateError.invalidBundleId }

    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let appStoreInfo = try await fetchAppStoreInfo()
    return appStoreInfo.toEntity(currentVersion: currentVersion)
  }

  // MARK: - Private

  /// 한국어 환경이면 kr 우선, 실패 시 us 폴백 (그 외는 반대).
  private func fetchAppStoreInfo() async throws -> AppStoreInfoDTO {
    let language = currentLanguage()
    let primary = language == "ko" ? "kr" : "us"
    let fallback = language == "ko" ? "us" : "kr"

    if let result = try? await fetchAppStoreInfo(country: primary) {
      return result
    }
    return try await fetchAppStoreInfo(country: fallback)
  }

  private func fetchAppStoreInfo(country: String) async throws -> AppStoreInfoDTO {
    let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=\(country)"
    guard let url = URL(string: urlString) else { throw AppUpdateError.invalidBundleId }

    do {
      let (data, _) = try await urlSession.data(from: url)
      let response = try JSONDecoder().decode(AppUpdateResponseDTO.self, from: data)
      guard let appInfo = response.results.first else { throw AppUpdateError.appNotFound }
      return appInfo
    } catch is DecodingError {
      throw AppUpdateError.decodingError
    } catch let error as AppUpdateError {
      throw error
    } catch {
      Log.error("[AppUpdate] lookup 실패(\(country)): \(error.localizedDescription)")
      throw AppUpdateError.from(error)
    }
  }

  private func currentLanguage() -> String {
    if let code = Locale.current.language.languageCode?.identifier { return code }
    if let preferred = Locale.preferredLanguages.first { return String(preferred.prefix(2)) }
    return "en"
  }
}
