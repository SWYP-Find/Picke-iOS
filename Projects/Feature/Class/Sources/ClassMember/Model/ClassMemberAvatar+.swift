//
//  ClassMemberAvatar+.swift
//  Class
//
//  Created by Picke on 10/11/26.
//

import ClassDomainInterface
import PickeDesignKit

extension ClassMemberAvatar {
  var imageAsset: ImageAsset {
    switch self {
    case .lion: return .classMemberLion
    case .koala: return .classMemberKoala
    case .bear: return .classMemberBear
    case .penguin: return .classMemberPenguin
    case .dog: return .classMemberDog
    case .alpaca: return .classMemberAlpaca
    }
  }
}
