//
//  AudioPlayerRepositoryImpl.swift
//  Repository
//

import AVFoundation
import DomainInterface
import Foundation

public final class AudioPlayerRepositoryImpl: AudioPlayerInterface, @unchecked Sendable {
  private let service: AudioPlayerService

  public init() {
    service = AudioPlayerService.shared
  }

  @discardableResult
  public func load(url: URL) async -> Bool {
    await service.load(url: url)
  }

  public func play() async {
    await service.play()
  }

  public func pause() async {
    await service.pause()
  }

  public func seek(to time: TimeInterval) async {
    await service.seek(to: time)
  }

  public func duration() async -> TimeInterval {
    await service.duration()
  }

  public func currentTimes() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await time in service.currentTimeStream() {
          continuation.yield(time)
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

@MainActor
final class AudioPlayerService {
  static let shared = AudioPlayerService()

  private let player = AVPlayer()
  private var timeContinuations: [UUID: AsyncStream<TimeInterval>.Continuation] = [:]
  private var timeObserverToken: Any?

  private init() {
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    try? AVAudioSession.sharedInstance().setActive(true)
    installPeriodicObserver()
  }

  private func installPeriodicObserver() {
    let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
    timeObserverToken = player.addPeriodicTimeObserver(
      forInterval: interval,
      queue: .main
    ) { [weak self] time in
      let seconds = max(0, time.seconds.isFinite ? time.seconds : 0)
      Task { @MainActor [weak self] in
        self?.timeContinuations.values.forEach { $0.yield(seconds) }
      }
    }
  }

  func load(url: URL) async -> Bool {
    let item = AVPlayerItem(url: url)
    player.replaceCurrentItem(with: item)
    await player.seek(to: .zero)
    // 자산이 실제 재생 가능한지 확인 → 실패 시 오류 배너 노출 트리거.
    do {
      return try await item.asset.load(.isPlayable)
    } catch {
      return false
    }
  }

  func play() { player.play() }
  func pause() { player.pause() }

  func seek(to time: TimeInterval) async {
    await player.seek(
      to: CMTime(seconds: max(0, time), preferredTimescale: 600),
      toleranceBefore: .zero,
      toleranceAfter: .zero
    )
  }

  func duration() async -> TimeInterval {
    guard let item = player.currentItem else { return 0 }
    if let duration = try? await item.asset.load(.duration) {
      return duration.seconds.isFinite ? duration.seconds : 0
    }
    return 0
  }

  func currentTimeStream() -> AsyncStream<TimeInterval> {
    AsyncStream { continuation in
      let id = UUID()
      timeContinuations[id] = continuation
      continuation.onTermination = { @Sendable [weak self] _ in
        Task { @MainActor in
          self?.timeContinuations.removeValue(forKey: id)
        }
      }
    }
  }
}
