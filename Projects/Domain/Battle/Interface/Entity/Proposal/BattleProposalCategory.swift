//
//  BattleProposalCategory.swift
//  Entity
//
//  배틀 주제 제안 카테고리 (POST /api/v1/battles/proposals 의 category).
//

import Foundation

public enum BattleProposalCategory: String, CaseIterable, Identifiable, Equatable {
  case philosophy = "철학"
  case literature = "문학"
  case art = "예술"
  case science = "과학"
  case society = "사회"
  case history = "역사"

  public var id: String { rawValue }

  /// 표시명 (= API 전송값).
  public var title: String { rawValue }
}
