//
//  NetworkAssembly.swift
//  CoreAssembly
//
//  Created by Picke on 10/11/26.
//

import PickeNetwork
import PickeNetworkInterface

public enum NetworkAssembly {
  public static func plainClient() -> any PickeNetworkClient {
    NetworkClientFactory.plain()
  }
}
