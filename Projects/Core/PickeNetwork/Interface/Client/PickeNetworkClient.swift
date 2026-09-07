//
//  PickeNetworkClient.swift
//  PickeNetworkInterface
//

import Foundation

/// 일반 요청 / 멀티파트 업로드 / 파일 PUT 을 한 계약으로 묶은 네트워크 클라이언트.
public protocol PickeNetworkClient: PickeRequestClient, PickeUploadClient, PickeFileUploadClient {}
