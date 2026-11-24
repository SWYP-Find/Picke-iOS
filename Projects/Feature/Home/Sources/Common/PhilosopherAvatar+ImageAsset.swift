//
//  PhilosopherAvatar+ImageAsset.swift
//  Home
//
//  Created by Picke on 10/11/26.
//

import PickeDesignKit
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
