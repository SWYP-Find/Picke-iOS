//
//  ClassMemberAvatarTests.swift
//  ClassTests
//
//  Created by Picke on 10/11/26.
//

@testable import Class
import ClassDomainInterface
import PickeDesignKit
import Testing
import UIKit

struct ClassMemberAvatarTests {
  @Test
  func 모든_멤버_아바타는_디자인킷_이미지를_불러온다() {
    for avatar in ClassMemberAvatar.allCases {
      #expect(UIImage(avatar.imageAsset) != nil, "Missing avatar image: \(avatar.rawValue)")
    }
  }
}
