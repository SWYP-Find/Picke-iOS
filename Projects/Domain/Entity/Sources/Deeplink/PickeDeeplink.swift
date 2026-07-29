//
//  PickeDeeplink.swift
//  Picke
//

import Foundation

public enum PickeDeeplink: Equatable, Sendable {
  /// NEW_BATTLE → 배틀 상세.
  case battle(battleId: Int)
  /// COMMENT_LIKE / NEW_COMMENT → 관점 화면 + commentId 스크롤/하이라이트.
  case perspective(perspectiveId: Int, commentId: Int?)
  /// CREDIT_EARNED → 마이페이지 포인트 내역.
  case point
  /// POLICY_CHANGE → 서비스 약관 웹뷰.
  case terms

  /// 콜드 스타트 대기 딥링크 저장용 문자열 인코딩 (PickeDeeplinkParser.parse(urlString:) 로 복원).
  public var encoded: String {
    switch self {
    case let .battle(battleId):
      return "battle/\(battleId)"
    case let .perspective(perspectiveId, commentId):
      if let commentId {
        return "perspective/\(perspectiveId)?commentId=\(commentId)"
      }
      return "perspective/\(perspectiveId)"
    case .point:
      return "point"
    case .terms:
      return "terms"
    }
  }
}

public enum PickeDeeplinkParser {
  /// 푸시 payload(userInfo) → 딥링크. iOS 는 notification+data 라 top-level 에 data 키가 존재.
  public static func parse(pushPayload userInfo: [AnyHashable: Any]) -> PickeDeeplink? {
    switch userInfo["type"] as? String {
    case "BATTLE":
      if let battleId = intValue(userInfo["battleId"]) {
        return .battle(battleId: battleId)
      }
    case "COMMENT":
      if let perspectiveId = intValue(userInfo["perspectiveId"]) {
        return .perspective(
          perspectiveId: perspectiveId,
          commentId: intValue(userInfo["commentId"])
        )
      }
    case "CREDIT", "POINT":
      return .point
    default:
      break
    }
    // fallback: url(유니버설 링크) 파싱.
    if let url = userInfo["url"] as? String {
      return parse(urlString: url)
    }
    return nil
  }

  /// 유니버설 링크 · 커스텀 스킴 모두 흡수.
  /// - https://picke.store/battle/55 · https://picke.store/perspective/45?commentId=678
  /// - picke://battle/55 · picke://perspective/45?commentId=678
  public static func parse(urlString: String) -> PickeDeeplink? {
    guard let components = URLComponents(string: urlString) else { return nil }
    var path = components.path.split(separator: "/").map(String.init)
    // 커스텀 스킴(picke://battle/55) 은 host 가 리소스 타입이므로 path 앞에 합친다.
    if let host = components.host, !host.isEmpty, host != "picke.store" {
      path.insert(host, at: 0)
    }
    // 포인트는 단일 경로(picke://point).
    if let first = path.first, ["point", "points", "credit", "credits"].contains(first) {
      return .point
    }
    // 약관도 단일 경로(picke://terms).
    if let first = path.first, ["terms", "policy"].contains(first) {
      return .terms
    }
    guard path.count >= 2 else { return nil }

    switch path[0] {
    case "battle", "battles":
      if let battleId = Int(path[1]) { return .battle(battleId: battleId) }
    case "perspective", "perspectives":
      if let perspectiveId = Int(path[1]) {
        let commentId = components.queryItems?
          .first { $0.name == "commentId" }?.value
          .flatMap(Int.init)
        return .perspective(perspectiveId: perspectiveId, commentId: commentId)
      }
    default:
      break
    }
    return nil
  }

  /// 인앱 알림함 항목(detailCode) → 딥링크.
  public static func parse(
    detailCode: String,
    referenceId: Int?,
    perspectiveId: Int?
  ) -> PickeDeeplink? {
    switch detailCode {
    case "NEW_BATTLE":
      return referenceId.map { .battle(battleId: $0) }
    case "COMMENT_LIKE", "NEW_COMMENT":
      return perspectiveId.map { .perspective(perspectiveId: $0, commentId: referenceId) }
    case "CREDIT_EARNED":
      return .point
    case "POLICY_CHANGE":
      return .terms
    default:
      // PROMOTION 등은 이동 없음(텍스트만).
      return nil
    }
  }

  /// FCM/APNs data 값은 문자열일 수 있어 String/Int 모두 허용.
  private static func intValue(_ value: Any?) -> Int? {
    if let int = value as? Int { return int }
    if let string = value as? String { return Int(string) }
    return nil
  }
}

public extension Notification.Name {
  /// 푸시/인앱 알림 탭으로 발생한 화면 이동 요청. userInfo["deeplink"] = PickeDeeplink.encoded
  static let pickeDeeplink = Notification.Name("PickeDeeplink")
}
