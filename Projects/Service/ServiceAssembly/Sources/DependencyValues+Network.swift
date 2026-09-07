//
//  DependencyValues+Network.swift
//  ServiceAssembly
//
//  네트워크·인증의 live 구현을 DependencyKey 에 등록한다.
//
//  두 값 모두 Keychain 과 인증 세션을 함께 다루는 NetworkContainer 가 만든다.
//  Interface 쪽에는 계약과 테스트값만 두고, 실제 조립은 이 계층이 맡는다.
//

import PickeAuthInterface
import PickeNetworkInterface

import Dependencies

extension NetworkClientDependency: DependencyKey {
  public static var liveValue: any PickeNetworkClient {
    NetworkContainer.authenticatedClient
  }
}

extension AuthServiceDependency: DependencyKey {
  public static var liveValue: any AuthService {
    NetworkContainer.authService
  }
}
