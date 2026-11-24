//
//  PlaybackAction.swift
//  PickeAnalyticsInterface
//
//  Created by Picke on 10/11/26.
//

import Foundation

public enum PlaybackAction: String, Sendable {
  case play
  case pause
  case skip15s = "skip_15s"
  case replay
  case seek
}
