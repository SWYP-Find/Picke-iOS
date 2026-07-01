//
//  AnalyticsButton.swift
//  UseCase
//
//  ui_action 이벤트의 버튼 식별자(enum). `{screen}_{button}` 규약. 신규 버튼은 여기에 등록.
//

import Foundation

public enum AnalyticsButton: String, Sendable {
  // 홈
  case homeMore = "home_more"
  case homeNotification = "home_notification"
  // 마이페이지
  case mypageNotification = "mypage_notification"
  case mypageSettings = "mypage_settings"
  case pointCharge = "point_charge"
  // 설정
  case settingsLogout = "settings_logout"
  case settingsWithdraw = "settings_withdraw"
  // 빠른 배틀
  case quickBattleBack = "quick_battle_back"
  case quickBattleOption = "quick_battle_option"
  case quickBattleEnter = "quick_battle_enter"
  // 탭바
  case tabHome = "tab_home"
  case tabExplore = "tab_explore"
  case tabQuickBattle = "tab_quick_battle"
  case tabMypage = "tab_mypage"
}
