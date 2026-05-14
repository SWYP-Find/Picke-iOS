//
//  LogOutDTO.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

public struct LogoutDataDTO: Decodable, Equatable {
  public let loggedOut: Bool

  public init(loggedOut: Bool) {
    self.loggedOut = loggedOut
  }

  private enum CodingKeys: String, CodingKey {
    case loggedOut = "logged_out"
  }
}

public struct LogOutDTO: Decodable {
  public let statusCode: Int
  public let data: LogoutDataDTO?
  public let error: APIErrorDTO?

  public init(
    statusCode: Int,
    data: LogoutDataDTO? = nil,
    error: APIErrorDTO? = nil
  ) {
    self.statusCode = statusCode
    self.data = data
    self.error = error
  }
}
