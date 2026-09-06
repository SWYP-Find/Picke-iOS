//
//  AudioPlayerInterface.swift
//  AudioPlayerServiceInterface
//

import Dependencies
import Foundation
import WeaveDI

public protocol AudioPlayerInterface: Sendable {
  /// 음원을 로드하고 재생 가능 여부를 반환한다. (false = 오디오 로딩 실패)
  @discardableResult
  func load(url: URL) async -> Bool
  func play() async
  func pause() async
  func seek(to time: TimeInterval) async
  func duration() async -> TimeInterval
  func currentTimes() -> AsyncStream<TimeInterval>
}

public struct DefaultAudioPlayerImpl: AudioPlayerInterface {
  public init() {}
  public func load(url _: URL) async -> Bool { true }
  public func play() async {}
  public func pause() async {}
  public func seek(to _: TimeInterval) async {}
  public func duration() async -> TimeInterval { 0 }
  public func currentTimes() -> AsyncStream<TimeInterval> { AsyncStream { _ in } }
}

public struct AudioPlayerDependency: DependencyKey {
  public static var liveValue: AudioPlayerInterface {
    UnifiedDI.resolve(AudioPlayerInterface.self) ?? DefaultAudioPlayerImpl()
  }

  public static var testValue: AudioPlayerInterface {
    UnifiedDI.resolve(AudioPlayerInterface.self) ?? DefaultAudioPlayerImpl()
  }

  public static var previewValue: AudioPlayerInterface = liveValue
}

public extension DependencyValues {
  var audioPlayer: AudioPlayerInterface {
    get { self[AudioPlayerDependency.self] }
    set { self[AudioPlayerDependency.self] = newValue }
  }
}
