//
//  AdClickData.swift
//  UseCase
//

import Foundation

/// 광고 노출 형태. 같은 지면이라도 형태가 다르면 클릭 성격이 달라 따로 본다.
public enum AdFormat: String, Sendable {
  case banner
  case native
  case popup
  case rewarded
}

public struct AdClickData: Sendable {
  public let placement: AdPlacement
  public let format: AdFormat
  /// 광고 단위 식별자(Info.plist 키). 지면이 같아도 단위별 성과를 나눠 보기 위해 남긴다.
  public let unit: String?

  public init(placement: AdPlacement, format: AdFormat, unit: String? = nil) {
    self.placement = placement
    self.format = format
    self.unit = unit
  }
}
