import AudioPlayerServiceInterface
import Dependencies
import Foundation

/// 클래스 목 시나리오를 기기 음원 없이 재생하는 8초 타이머.
struct ClassMockAudioPlayer: AudioPlayerInterface {
  private let clock = Clock()

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

  func seek(to time: TimeInterval) async {
    await clock.seek(to: time)
  }

  func duration() async -> TimeInterval {
    8
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
  private var elapsed: TimeInterval = 0
  private var startedAt: Date?

  func reset() {
    elapsed = 0
    startedAt = nil
  }

  func play() {
    guard startedAt == nil else { return }
    startedAt = Date()
  }

  func pause() {
    elapsed = currentTime()
    startedAt = nil
  }

  func seek(to time: TimeInterval) {
    elapsed = min(max(0, time), duration)
    if startedAt != nil {
      startedAt = Date()
    }
  }

  func currentTime() -> TimeInterval {
    let running = startedAt.map { Date().timeIntervalSince($0) } ?? 0
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
