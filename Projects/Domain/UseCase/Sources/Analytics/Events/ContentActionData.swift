//
//  ContentActionData.swift
//  UseCase
//

import Foundation

public enum ContentActionType: String, Sendable {
  case battleCardTap = "battle_card_tap"
  case heroTap = "hero_tap"
  case newBattleTap = "new_battle_tap"
  case voteCardTap = "vote_card_tap"
  case voteResultView = "vote_result_view"
  case quickBattleNext = "quick_battle_next"
  case exploreCategoryTap = "explore_category_tap"
  case battleRecommendClose = "battle_recommend_close"
}

public struct ContentActionData: Sendable {
  public let action: ContentActionType
  public let contentID: String?
  public let section: String?

  public init(action: ContentActionType, contentID: String? = nil, section: String? = nil) {
    self.action = action
    self.contentID = contentID
    self.section = section
  }
}
