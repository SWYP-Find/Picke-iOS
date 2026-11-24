//
//  AttendanceLiveDependencies.swift
//  AttendanceDomain
//
//  Created by Picke on 10/11/26.
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AttendanceDomainInterface
import ComposableArchitecture

extension AttendanceUseCaseDependency: DependencyKey {
  public static var liveValue: AttendanceInterface { AttendanceUseCaseImpl() }
}

extension AttendanceRepositoryDependency: DependencyKey {
  public static var liveValue: AttendanceInterface { AttendanceRepositoryImpl() }
}
