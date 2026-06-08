//
//  PhilosopherAvatar.swift
//  Entity
//

import Foundation

/// 사전 투표창 / 새로운 배틀 카드에서 사용되는 철학자 아바타. raw value 는 화면 표시 이름.
public enum PhilosopherAvatar: String, CaseIterable, Equatable, Hashable {
  case plato = "플라톤"
  case sartre = "사르트르"
  case sunja = "순자"
}
