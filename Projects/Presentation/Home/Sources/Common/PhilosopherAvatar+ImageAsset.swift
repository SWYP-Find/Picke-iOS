//
//  PhilosopherAvatar+ImageAsset.swift
//  Home
//
//  Home 모듈 내부에서만 사용하는 매핑. Entity 가 PickeDesignKit 에 의존하지 않도록
//  ImageAsset 매핑은 Home 모듈 내부 internal extension 으로 둔다.
//

import PickeDesignKit
import Entity
import BattleDomainInterface

extension PhilosopherAvatar {
  var imageAsset: ImageAsset {
    switch self {
    case .plato: .avatarPlato
    case .sartre: .avatarSartre
    case .sunja: .avatarSunja
    }
  }
}
