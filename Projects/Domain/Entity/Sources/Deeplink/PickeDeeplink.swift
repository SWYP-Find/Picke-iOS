//
//  PickeDeeplink.swift
//  Picke
//
//  알림 → 화면 이동 목적지. (TimeSpot-iOS DeeplinkRouter 패턴)
//  푸시 data 페이로드 / 유니버설 링크 URL / 인앱 알림(detailCode) 세 경로를 하나로 흡수.
//

import Foundation

public enum PickeDeeplink: Equatable, Sendable {
  /// NEW_BATTLE → 배틀 상세.
  case battle(battleId: Int)
  /// COMMENT_LIKE / NEW_COMMENT → 관점 화면 + commentId 스크롤/하이라이트.
  case perspective(perspectiveId: Int, commentId: Int?)

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
    default:
      break
    }
    // fallback: url(유니버설 링크) 파싱.
    if let url = userInfo["url"] as? String {
      return parse(urlString: url)
    }
    return nil
  }

  /// https://picke.store/battle/55 · https://picke.store/perspective/45?commentId=678
  public static func parse(urlString: String) -> PickeDeeplink? {
    guard let components = URLComponents(string: urlString) else { return nil }
    let path = components.path.split(separator: "/").map(String.init)
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
    default:
      // CREDIT_EARNED / POLICY_CHANGE / PROMOTION 등은 이동 없음.
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
