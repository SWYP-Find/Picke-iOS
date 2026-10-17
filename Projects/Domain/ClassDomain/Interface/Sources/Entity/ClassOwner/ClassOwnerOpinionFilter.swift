//
//  ClassOwnerOpinionFilter.swift
//  ClassDomainInterface
//
//  Created by Picke on 10/11/26.
//

public enum ClassOwnerOpinionFilter: String, CaseIterable, Hashable, Sendable {
  case popular = "인기순"
  case latest = "최신순"
}
