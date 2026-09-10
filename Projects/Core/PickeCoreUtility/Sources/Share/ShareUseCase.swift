//
//  ShareUseCase.swift
//  PickeCoreUtility
//

import Foundation
import UIKit

import Dependencies
import PickeNetwork

/// 공유 시트 아이템(본문, 링크, 이미지)을 조립하는 클라이언트.
public struct ShareUseCase: Sendable {
  public var loadImageData: @Sendable (_ urlString: String) async -> Data?
  public var makeShareItem: @Sendable (_ content: ShareContent) async -> ShareItem

  public init(
    loadImageData: @escaping @Sendable (_ urlString: String) async -> Data?,
    makeShareItem: @escaping @Sendable (_ content: ShareContent) async -> ShareItem
  ) {
    self.loadImageData = loadImageData
    self.makeShareItem = makeShareItem
  }
}

extension ShareUseCase: DependencyKey {
  public static let liveValue = ShareUseCase(
    loadImageData: loadRemoteImageData,
    makeShareItem: { content in
      var items: [Any] = [content.displayText]

      if let url = URL(string: content.url) {
        items.append(url)
      } else {
        items.append(content.url)
      }

      if let snapshotData = content.snapshotData, let image = UIImage(data: snapshotData) {
        items.append(image)
      } else if let thumbnailURL = content.thumbnailURL,
                let data = await loadRemoteImageData(thumbnailURL),
                let image = UIImage(data: data)
      {
        items.append(image)
      }

      return ShareItem(items: items)
    }
  )

  public static let testValue = ShareUseCase(
    loadImageData: { _ in nil },
    makeShareItem: { ShareItem(items: [$0.displayText]) }
  )

  public static let previewValue = testValue

  private static let loadRemoteImageData: @Sendable (String) async -> Data? = { urlString in
    guard let url = URL(string: urlString) else { return nil }
    let startedAt = Date()

    do {
      let (data, response) = try await URLSession.shared.data(from: url)
      NetworkTelemetry.shared.record(
        NetworkTelemetryEvent(
          source: "vote_share_image",
          method: "GET",
          url: url,
          statusCode: (response as? HTTPURLResponse)?.statusCode,
          duration: Date().timeIntervalSince(startedAt),
          isSuccess: true
        )
      )
      return data
    } catch {
      NetworkTelemetry.shared.record(
        NetworkTelemetryEvent(
          source: "vote_share_image",
          method: "GET",
          url: url,
          statusCode: nil,
          duration: Date().timeIntervalSince(startedAt),
          isSuccess: false
        )
      )
      return nil
    }
  }
}

public extension DependencyValues {
  var shareUseCase: ShareUseCase {
    get { self[ShareUseCase.self] }
    set { self[ShareUseCase.self] = newValue }
  }
}
