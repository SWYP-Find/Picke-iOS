//
//  AnalyticsScreen.swift
//  UseCase
//

import Foundation

public enum AnalyticsScreen: String, Sendable {
  case splash
  case onboarding
  case login
  case home
  case explore
  case quickBattle = "quick_battle"
  case mypage
  case battleDetail = "battle_detail"
  case prevote
  case chatroom
  case curation
  case voteContent = "vote_content"
  case comment
  case commentReply = "comment_reply"
  case notification
  case point
  case settings
  case withdraw
  case recap
  case mainTab = "main_tab"
}
