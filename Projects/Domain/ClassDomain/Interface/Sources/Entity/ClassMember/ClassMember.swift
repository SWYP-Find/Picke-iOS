//
//  ClassMember.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public struct ClassMember: Equatable, Identifiable, Sendable {
  public let id: Int
  public let name: String
  public let isOwner: Bool
  public let avatar: ClassMemberAvatar?

  public init(
    id: Int,
    name: String,
    isOwner: Bool = false,
    avatar: ClassMemberAvatar? = nil
  ) {
    self.id = id
    self.name = name
    self.isOwner = isOwner
    self.avatar = avatar
  }
}
