//
//  ShareSnapshotRequest.swift
//  Chat
//
//  Created by Picke on 10/11/26.
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
