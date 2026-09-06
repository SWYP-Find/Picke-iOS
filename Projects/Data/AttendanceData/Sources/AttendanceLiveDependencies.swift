//
//  AttendanceLiveDependencies.swift
//  AttendanceData
//
//  이 모듈이 소유한 live 구현을 스스로 등록한다.
//

import AttendanceDomainInterface
import ComposableArchitecture

extension AttendanceRepositoryDependency: DependencyKey {
  public static var liveValue: AttendanceInterface { AttendanceRepositoryImpl() }
}
