//
//  PlaybackAction.swift
//  UseCase
//
//  playback_action(Tier3) 의 조작 종류.
//

import Foundation

public enum PlaybackAction: String, Sendable {
  case play
  case pause
  case skip15s = "skip_15s"
  case replay
  case seek
}
