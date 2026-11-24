//
//  ClassMockAudioPlayer.swift
//  Picke
//
//  Created by Picke on 10/11/26.
//

import AudioPlayerServiceInterface
import Dependencies
import Foundation

/// 클래스 목 시나리오를 기기 음원 없이 재생하는 8초 타이머.
struct ClassMockAudioPlayer: AudioPlayerInterface {
  private let clock: Clock

  init(now: @escaping @Sendable () -> Date = { Date() }) {
    clock = Clock(now: now)
  }

  func load(url: URL) async -> Bool {
    guard url.scheme == "picke-class-mock" else { return false }
    await clock.reset()
    return true
  }

  func play() async {
    await clock.play()
  }

  func pause() async {
    await clock.pause()
  }

  func setPlaybackRate(_ rate: Float) async {
    await clock.setPlaybackRate(rate)
  }

  func seek(to time: TimeInterval) async {
    await clock.seek(to: time)
  }

  func duration() async -> TimeInterval {
    8
  }

  func currentTime() async -> TimeInterval {
    await clock.currentTime()
  }

  func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      let task = Task {
        while !Task.isCancelled {
          await continuation.yield(clock.currentTime())
          try? await Task.sleep(for: .milliseconds(100))
        }
        continuation.finish()
      }
      continuation.onTermination = { @Sendable _ in task.cancel() }
    }
  }
}

private actor Clock {
  private let duration: TimeInterval = 8
  private let now: @Sendable () -> Date
  private var elapsed: TimeInterval = 0
  private var startedAt: Date?
  private var rate: Float = 1

  init(now: @escaping @Sendable () -> Date) {
    self.now = now
  }

  func reset() {
    elapsed = 0
    startedAt = nil
  }

  func play() {
    guard !Task.isCancelled else { return }
    guard startedAt == nil else { return }
    startedAt = now()
  }

  func pause() {
    elapsed = currentTime()
    startedAt = nil
  }

  func setPlaybackRate(_ newRate: Float) {
    guard [1, 1.25, 1.5, 2].contains(newRate) else { return }
    if startedAt != nil {
      elapsed = currentTime()
      startedAt = now()
    }
    rate = newRate
  }

  func seek(to time: TimeInterval) {
    elapsed = min(max(0, time), duration)
    if startedAt != nil {
      startedAt = now()
    }
  }

  func currentTime() -> TimeInterval {
    let running = startedAt.map { now().timeIntervalSince($0) * Double(rate) } ?? 0
    return min(duration, elapsed + running)
  }
}

private enum ClassMockAudioPlayerKey: DependencyKey {
  static let liveValue = ClassMockAudioPlayer()
  static var testValue: ClassMockAudioPlayer {
    ClassMockAudioPlayer()
  }

  static var previewValue: ClassMockAudioPlayer {
    ClassMockAudioPlayer()
  }
}

extension DependencyValues {
  var classMockAudioPlayer: ClassMockAudioPlayer {
    get { self[ClassMockAudioPlayerKey.self] }
    set { self[ClassMockAudioPlayerKey.self] = newValue }
  }
}
