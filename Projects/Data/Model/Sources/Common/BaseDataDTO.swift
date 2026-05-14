//
//  BaseDataDTO.swift
//  Model
//
//  Created by Wonji Suh on 5/14/26.
//

import Foundation

/// `BaseResponseDTO<T>` 의 `data` 필드에 들어갈 페이로드가 공통으로 채택하는 마커 프로토콜.
/// API 별 데이터 DTO 는 이 프로토콜을 채택해 `BaseResponseDTO` 와 안전하게 결합한다.
public protocol BaseDataDTO: Decodable, Equatable {}
