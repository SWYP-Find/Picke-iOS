//
//  ClassOwnerMemberSort.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public enum ClassOwnerMemberSort: String, CaseIterable, Hashable, Sendable {
  case name = "이름순"
  case participation = "참여 많은순"
  case needsReview = "확인 필요순"
}
