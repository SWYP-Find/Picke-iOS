//
//  PollAPI.swift
//  API
//
//  Created by Wonji Suh  on 5/19/26.
//

import Foundation

public enum PollAPI  {
  case detailPoll(pollId: Int)
  
  public var description: String {
    switch self {
    case .detailPoll(let pollId):
      return "/\(pollId)"
    }
  }
}
