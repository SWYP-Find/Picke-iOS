//
//  ShareUseCase.swift
//  UseCase
//

import Foundation
import UIKit

import ComposableArchitecture
import Entity

/// 공유 시트 아이템(본문·링크·이미지)을 조립하는 클라이언트.
public struct ShareUseCase: Sendable {
  /// 원격 이미지를 받음
  public var loadImageData: @Sendable (_ urlString: String) async -> Data?
  /// `ShareContent` 를 공유 시트에 넘길 아이템 배열로 조립한다.
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

      // 인스타 스토리/게시물 공유를 위해 카드 스냅샷을 우선 포함하고, 없을 때만 썸네일로 폴백.
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
    guard let url = URL(string: urlString),
          let (data, _) = try? await URLSession.shared.data(from: url)
    else { return nil }
    return data
  }
}

public extension DependencyValues {
  var shareUseCase: ShareUseCase {
    get { self[ShareUseCase.self] }
    set { self[ShareUseCase.self] = newValue }
  }
}
