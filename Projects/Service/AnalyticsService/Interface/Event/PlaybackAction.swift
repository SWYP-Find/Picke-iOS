//
//  PlaybackAction.swift
//  UseCase
//

import Foundation

public enum PlaybackAction: String, Sendable {
  case play
  case pause
  case skip15s = "skip_15s"
  case replay
  case seek
}
