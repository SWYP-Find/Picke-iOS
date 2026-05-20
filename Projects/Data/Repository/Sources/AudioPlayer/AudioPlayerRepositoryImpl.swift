//
//  AudioPlayerRepositoryImpl.swift
//  Repository
//
//  AVPlayer 기반 단일 오디오 플레이어 구현체.
//  AudioPlayerInterface 를 만족하며, 채팅방 / 배틀 상세 등 한 화면당 하나의 음원이
//  재생되는 환경을 가정한다.
//

import AVFoundation
import DomainInterface
import Foundation

public final class AudioPlayerRepositoryImpl: AudioPlayerInterface, @unchecked Sendable {
  private let service: AudioPlayerService

  public init() {
    service = AudioPlayerService.shared
  }

  public func load(url: URL) async {
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

  func load(url: URL) {
    let item = AVPlayerItem(url: url)
    player.replaceCurrentItem(with: item)
    player.seek(to: .zero)
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
