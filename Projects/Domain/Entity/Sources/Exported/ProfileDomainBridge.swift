//
//  ProfileDomainBridge.swift
//  Entity
//
//  Profile 계약이 Entity 에서 ProfileDomainInterface 로 이관됨에 따라,
//  아직 `import Entity` 로 Profile 타입을 참조하는 소비자(Presentation/Profile 등)의
//  빌드를 유지하기 위한 과도기 재노출 셸. Presentation 레이어 마이그레이션 시 제거.
//

@_exported import ProfileDomainInterface
