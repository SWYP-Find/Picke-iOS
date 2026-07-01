//
//  AnalyticsScreen.swift
//  UseCase
//
//  screen_view 이벤트의 화면 식별자(enum). 신규 화면은 여기에 등록.
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
