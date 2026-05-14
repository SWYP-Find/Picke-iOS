//
//  KakaoAuthCodeStore.swift
//  Data
//
//  Created by Assistant on 12/5/25.
//

import Foundation

/// 간단한 메모리 저장소: Kakao OAuth 콜백에서 받은 authorization code를 보관/소비한다.
public final actor KakaoAuthCodeStore {
    public static let shared = KakaoAuthCodeStore()
    private var code: String?
    private var continuations: [UUID: ContinuationEntry] = [:]

    private struct ContinuationEntry {
        let continuation: CheckedContinuation<String, Error>
        let timeoutTask: Task<Void, Never>
    }

    private init() {}

    public func save(_ code: String) {
        self.code = code
        let pending = continuations.values
        continuations.removeAll()
        pending.forEach { entry in
            entry.timeoutTask.cancel()
            entry.continuation.resume(returning: code)
        }
    }

    /// 기존 코드와 대기 상태를 모두 초기화
    public func reset() {
        code = nil
        let pending = continuations.values
        continuations.removeAll()
        pending.forEach { entry in
            entry.timeoutTask.cancel()
            entry.continuation.resume(throwing: NSError(domain: "KakaoAuthCodeStore", code: -999, userInfo: [NSLocalizedDescriptionKey: "Reset called"]))
        }
    }

    public func consume() -> String? {
        let value = code
        code = nil
        return value
    }

    public func waitForCode(timeout: TimeInterval = 60) async throws -> String {
        if let existing = consume() {
            return existing
        }

        return try await withCheckedThrowingContinuation { continuation in
            let id = UUID()
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                self.handleTimeout(id: id)
            }
            continuations[id] = ContinuationEntry(continuation: continuation, timeoutTask: timeoutTask)
        }
    }

    private func handleTimeout(id: UUID) {
        guard let entry = continuations.removeValue(forKey: id) else {
            return
        }
        entry.continuation.resume(throwing: AuthError.unknownError("Kakao 로그인 응답을 받지 못했습니다"))
    }
}
