//
//  AudioPlayerDependency+Live.swift
//  AudioPlayerService
//

import AudioPlayerServiceInterface
import ComposableArchitecture

// MARK: - Live

extension AudioPlayerDependency: DependencyKey {
  public static var liveValue: AudioPlayerInterface { AudioPlayerRepositoryImpl() }
}
