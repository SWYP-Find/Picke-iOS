//
//  DomainAssemblyExportTests.swift
//  DomainAssemblyTests
//

import Testing

// 엄브렐러가 제 역할을 하는지 보는 테스트라 개별 도메인 모듈은 일부러 import 하지 않는다.
import DomainAssembly

struct DomainAssemblyExportTests {
  /// 재노출이 하나라도 빠지면 이 파일이 컴파일되지 않는다.
  /// 화면 코드가 `import DomainAssembly` 하나로 도메인 전체를 쓰는 전제를 지킨다.
  @Test
  func 모든_도메인_인터페이스가_엄브렐러로_보인다() {
    let interfaces: [Any.Type] = [
      (any AppUpdateUseCase).self,
      (any AttendanceInterface).self,
      (any AuthUseCase).self,
      (any BattleInterface).self,
      (any CommentInterface).self,
      (any HomeInterface).self,
      (any NotificationInterface).self,
      (any PerspectiveInterface).self,
      (any ProfileInterface).self,
      (any SearchInterface).self,
    ]

    #expect(interfaces.count == 10)
  }
}
