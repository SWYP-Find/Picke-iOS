//
//  PhilosopherAvatar+ImageAsset.swift
//  Home
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
