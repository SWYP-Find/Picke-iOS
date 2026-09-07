//
//  NetworkAssembly.swift
//  CoreAssembly
//

import PickeNetwork
import PickeNetworkInterface

public enum NetworkAssembly {
  public static func plainClient() -> any PickeNetworkClient {
    NetworkClientFactory.plain()
  }
}
