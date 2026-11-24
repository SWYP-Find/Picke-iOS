//
//  AudioPlayerDependency+Live.swift
//  AudioPlayerService
//
//  Created by Picke on 10/11/26.
//

import AudioPlayerServiceInterface
import ComposableArchitecture

// MARK: - Live

extension AudioPlayerDependency: DependencyKey {
  public static var liveValue: AudioPlayerInterface { AudioPlayerRepositoryImpl() }
}
