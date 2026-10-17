//
//  AudioPlayerServiceTests.swift
//  AudioPlayerServiceTests
//
//  Created by Picke on 10/11/26.
//

import AVFoundation
@testable import AudioPlayerService
import Testing

@MainActor
struct AudioPlayerServiceTests {
  @Test
  func changingRateWhilePausedOnlyUpdatesDefaultRate() {
    let player = AVPlayer()
    let service = AudioPlayerService(player: player, configuresSession: false)

    service.setPlaybackRate(1.5)
    #expect(player.defaultRate == 1.5)
    #expect(player.rate == 0)

    service.setPlaybackRate(.nan)
    service.setPlaybackRate(3)
    #expect(player.defaultRate == 1.5)
    #expect(player.rate == 0)
  }

  @Test
  func playPauseResumeRetainsConfiguredRate() {
    let player = PlaybackCommandSpy()
    let service = AudioPlayerService(player: player, configuresSession: false)

    service.setPlaybackRate(2)
    service.play()
    #expect(player.rate == 2)
    service.pause()
    #expect(player.defaultRate == 2)
    #expect(player.rate == 0)

    service.play()
    #expect(player.rate == 2)
    service.setPlaybackRate(1.5)
    #expect(player.defaultRate == 1.5)
    #expect(player.rate == 1.5)
  }
}

/// Verifies service commands independently of asset loading and hardware playback.
private final class PlaybackCommandSpy: AVPlayer, @unchecked Sendable {
  private var recordedRate: Float = 0
  private var configuredRate: Float = 1

  override var rate: Float {
    get { recordedRate }
    set { recordedRate = newValue }
  }

  override var defaultRate: Float {
    get { configuredRate }
    set { configuredRate = newValue }
  }

  override func play() {
    rate = defaultRate
  }

  override func pause() {
    rate = 0
  }
}
