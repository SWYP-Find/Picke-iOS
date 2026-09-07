//
//  NetworkContainer.swift
//  ServiceAssembly
//

import CoreAssembly
import PickeAuth
import PickeAuthInterface
import PickeNetworkInterface

public enum NetworkContainer {
  private static let assembly = makeAssembly()

  public static var authenticatedClient: any PickeNetworkClient {
    assembly.authenticatedClient
  }

  public static var authService: any AuthService {
    assembly.authService
  }

  private static func makeAssembly() -> Assembly {
    let plainClient = NetworkAssembly.plainClient()
    let auth = AuthFactory.make(
      refreshClient: plainClient,
      keychain: StorageAssembly.keychain
    )

    return Assembly(
      authenticatedClient: auth.authenticatedClient,
      authService: auth
    )
  }
}

private extension NetworkContainer {
  struct Assembly {
    let authenticatedClient: any PickeNetworkClient
    let authService: any AuthService
  }
}
