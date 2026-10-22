//
//  ClassPreviewAuditView.swift
//  PickeClassAuditHost
//
//  Created by Picke on 10/22/26.
//

import AudioPlayerServiceInterface
import BattleDomainInterface
import ComposableArchitecture
import FeatureAssembly
import PickeAnalyticsInterface
import SwiftUI

struct ClassPreviewAuditView: View {
  @Bindable private var store: StoreOf<ClassBattlePreviewFeature>

  init() {
    store = Store(initialState: ClassBattlePreviewReferenceFixture.makeState()) {
      ClassBattlePreviewFeature()
        .dependency(\.classBattlePreviewDependencies, .init(
          battleUseCase: MockBattleRepository(),
          audioPlayer: DefaultAudioPlayerImpl(),
          analyticsUseCase: .testValue
        ))
    }
  }

  var body: some View {
    ClassBattlePreviewView(store: store)
      .accessibilityIdentifier("class-preview-reference")
  }
}
