//
//  TermsDocument.swift
//  Entity
//
//  약관 동의 항목. .pen `애플 구글_약관 동의` 기준 (필수 2종).
//

import Foundation

public enum TermsDocument: String, CaseIterable, Identifiable, Hashable {
  case service
  case privacy

  public var id: String { rawValue }

  public var title: String {
    switch self {
    case .service: "(필수) 서비스 이용약관"
    case .privacy: "(필수) 개인정보처리방침"
    }
  }

  public var urlString: String {
    switch self {
    case .service: "https://picke.store/terms"
    case .privacy: "https://picke.store/privacy-policy"
    }
  }

  /// 동의가 필수인 항목들.
  public static var requiredCases: [TermsDocument] { allCases }
}
