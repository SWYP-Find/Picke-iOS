//
//  ShareSnapshotRequest.swift
//  Chat
//

import Foundation

public struct ShareSnapshotRequest: Equatable, Identifiable {
  public let id: UUID
  public let avatarImageData: [Int: Data]

  public init(
    id: UUID = UUID(),
    avatarImageData: [Int: Data]
  ) {
    self.id = id
    self.avatarImageData = avatarImageData
  }
}
