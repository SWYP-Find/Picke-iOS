//
//  ClassBattlePreviewRow.swift
//  Class
//
//  Created by Picke on 11/20/26.
//

import HomeDomainInterface

/// 미리듣기 대사 한 줄. Android `ScenarioChatBubble` 에 넘기는 값과 같다.
public struct ClassBattlePreviewRow: Equatable, Identifiable {
  public let script: ScenarioScript
  public let speaker: ChatSpeaker
  /// 앞 대사와 화자가 다를 때만 아바타·이름을 보인다.
  public let showsHeader: Bool
  /// 재생 중인 대사만 진하게 보인다.
  public let isActive: Bool
  /// 화자가 바뀌는 두 번째 묶음부터 위 간격을 더 둔다.
  public let hasTopSpacing: Bool

  public var id: Int { script.id }

  public init(
    script: ScenarioScript,
    speaker: ChatSpeaker,
    showsHeader: Bool,
    isActive: Bool,
    hasTopSpacing: Bool
  ) {
    self.script = script
    self.speaker = speaker
    self.showsHeader = showsHeader
    self.isActive = isActive
    self.hasTopSpacing = hasTopSpacing
  }
}
