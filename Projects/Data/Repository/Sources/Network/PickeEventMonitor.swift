//
//  PickeEventMonitor.swift
//  Repository
//

import Alamofire
import Foundation
import LogMacro

struct PickeEventMonitor: EventMonitor {
  let queue = DispatchQueue(label: "store.picke.network.logger")

  /// 바디 로그 최대 길이(초과 시 잘라냄).
  private let maxBodyLength = 4096

  // MARK: 요청 생성 실패 (URL/파라미터 인코딩 등 — 전송 전)

  func request(_: Request, didFailToCreateURLRequestWithError error: AFError) {
    Log.error("❌ [요청 생성 실패] \(error.localizedDescription)")
  }

  // MARK: 요청+응답 (응답 시점에 한 덩어리로 묶어서 로깅)

  func request(
    _: DataRequest,
    didParseResponse response: DataResponse<some Sendable, AFError>
  ) {
    let urlRequest = response.request
    let method = urlRequest?.httpMethod ?? "?"
    let url = urlRequest?.url?.absoluteString ?? "?"
    let status = response.response?.statusCode ?? -1
    let milliseconds = Int((response.metrics?.taskInterval.duration ?? 0) * 1000)
    let isFailure = response.error != nil

    var lines = ["\(isFailure ? "❌" : "✅") \(method) \(url) → \(status) (\(milliseconds)ms)"]

    // ── 요청 ──
    if let headers = urlRequest?.allHTTPHeaderFields, !headers.isEmpty {
      lines.append("  · Request Headers\n\(format(headers))")
    }
    if let body = urlRequest?.httpBody, !body.isEmpty {
      lines.append("  · Request Body\n\(indent(prettyBody(body)))")
    }

    // ── 응답 ──
    if let error = response.error {
      lines.append("  · Error\n       \(error.localizedDescription)")
      if let underlying = error.underlyingError {
        lines.append("       underlying: \(underlying.localizedDescription)")
      }
    }
    if let data = response.data, !data.isEmpty {
      lines.append("  · Response Body\n\(indent(prettyBody(data)))")
    }

    let message = lines.joined(separator: "\n")
    if isFailure {
      Log.error(message)
    } else {
      Log.debug(message)
    }
  }
}

private extension PickeEventMonitor {
  /// 헤더를 정렬해 한 줄씩 들여쓰기.
  func format(_ headers: [String: String]) -> String {
    headers
      .sorted { $0.key < $1.key }
      .map { "       \($0.key): \($0.value)" }
      .joined(separator: "\n")
  }

  /// 여러 줄 텍스트를 들여쓰기(바디 블록 정렬용).
  func indent(_ text: String) -> String {
    text.split(separator: "\n", omittingEmptySubsequences: false)
      .map { "       \($0)" }
      .joined(separator: "\n")
  }

  /// JSON 이면 pretty-print, 아니면 UTF-8 문자열. 길면 잘라낸다.
  func prettyBody(_ data: Data) -> String {
    let text: String = if let object = try? JSONSerialization.jsonObject(with: data),
                          let pretty = try? JSONSerialization.data(
                            withJSONObject: object,
                            options: [.prettyPrinted, .withoutEscapingSlashes]
                          ),
                          let string = String(data: pretty, encoding: .utf8)
    {
      string
    } else {
      String(data: data, encoding: .utf8) ?? "<\(data.count) bytes>"
    }
    guard text.count > maxBodyLength else { return text }
    return text.prefix(maxBodyLength) + "… (truncated)"
  }
}
