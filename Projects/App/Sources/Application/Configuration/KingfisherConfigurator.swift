//
//  KingfisherConfigurator.swift
//  App
//

import Foundation

import Kingfisher
import NetworkModule
import PickeStorageInterface

import Domain

enum KingfisherConfigurator {
  private static let telemetryDelegate = KingfisherTelemetryDelegate()

  /// 보호 이미지 (picke 백엔드 `/api/v1/resources/...`) 에만 Bearer 토큰을 첨부한다.
  /// 그 외 외부 호스트 (picsum.photos / 카카오 CDN 등) 로는 토큰을 절대 보내지 않는다.
  private static let protectedHostSuffixes: Set<String> = [
    "picke.store",
    "dev.picke.store",
  ]

  static func configureAuthorizedDownloader(
    keychainManager: KeychainManaging
  ) {
    let modifier = AnyModifier { request in
      var req = request

      guard
        let url = req.url,
        let host = url.host?.lowercased(),
        protectedHostSuffixes.contains(where: { host == $0 || host.hasSuffix(".\($0)") }),
        url.path.hasPrefix("/api/"),
        let token = keychainManager.accessToken(), !token.isEmpty
      else {
        return req
      }

      req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      return req
    }

    KingfisherManager.shared.defaultOptions = [
      .requestModifier(modifier),
    ]
    KingfisherManager.shared.downloader.delegate = telemetryDelegate
  }
}

private final class KingfisherTelemetryDelegate: ImageDownloaderDelegate, @unchecked Sendable {
  private let lock = NSLock()
  private var startedAtByURL: [URL: Date] = [:]

  func imageDownloader(
    _: ImageDownloader,
    willDownloadImageForURL url: URL,
    with _: URLRequest?
  ) {
    lock.withLock {
      startedAtByURL[url] = Date()
    }
  }

  func imageDownloader(
    _: ImageDownloader,
    didFinishDownloadingImageForURL url: URL,
    with response: URLResponse?,
    error: Error?
  ) {
    let startedAt = lock.withLock {
      startedAtByURL.removeValue(forKey: url) ?? Date()
    }
    NetworkTelemetry.shared.record(
      NetworkTelemetryEvent(
        source: "kingfisher",
        method: "GET",
        url: url,
        statusCode: (response as? HTTPURLResponse)?.statusCode,
        duration: Date().timeIntervalSince(startedAt),
        isSuccess: error == nil
      )
    )
  }
}
