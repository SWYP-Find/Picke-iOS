# Class Android/iOS API 대조 (2026-10-29)

기준: [Android `develop` `05c14af`](https://github.com/SWYP-Find/Picke-android/tree/05c14af23f0246e0e0f6d49e835dfb5151828696), [서버 클래스 API 명세 `1dc6db2`](https://github.com/SWYP-Find/Server/blob/1dc6db2c5de786bd7ba51ec3a052724102010c27/docs/api-specs/class-api.md), 이 저장소의 현재 작업 브랜치. Android의 열린 PR은 없으며 [#135 AI 토론](https://github.com/SWYP-Find/Picke-android/pull/135), [#137 결과](https://github.com/SWYP-Find/Picke-android/pull/137), [#139 후속 수정](https://github.com/SWYP-Find/Picke-android/pull/139)이 머지된 상태다. 코드와 명세의 정적 대조이며 인증된 실서버 호출이나 화면 일치의 증거는 아니다.

## Endpoint

Android `ClassroomApi` 30개, `VoteApi`의 클래스 전용 2개, `PerspectiveApi`의 클래스 전용 3개에 있는 클래스 관련 endpoint 35개 모두 iOS에 대응 구현이 있다. iOS 경로는 `Projects/Service/APIEndpoint/Sources/Class/`의 Ticket, Room, Member, Battle, TopicDraft, Recommendation 서비스에 있다. 공통 요청의 경로·메서드·주요 body/query 필드는 일치한다.

| 영역 | Android | iOS와 서버 명세 대조 |
| --- | --- | --- |
| 이용권·클래스·가입·멤버 | `ClassroomApi.kt` | 19개 endpoint 대응. 클래스 생성의 선택적 `ownerDisplayName`·`requestKey`, 초안 제안의 선택적 `filter`는 iOS가 추가 지원한다. |
| 투표·의견 | `ClassroomApi.kt`, `VoteApi.kt`, `PerspectiveApi.kt` | 8개 endpoint 대응. iOS는 중간 투표와 투표 이력의 `midVotes`를 추가 지원한다. |
| Android에 아직 없는 서버 기능 | 해당 API 없음 | iOS는 초안 조회·직접 수정 검증과 중간 투표를 추가 구현했다. Android에도 AI 토론·답글·재시도, 결과·내 리포트·인사이트·재시도 API와 ViewModel 연결이 머지됐다. |

## 계약 차이와 처리

| 항목 | 확인 결과 |
| --- | --- |
| 클래스 의견 작성자 `userTag` | 서버 응답은 `null`일 수 있고 Android DTO도 nullable이다. iOS DTO를 optional로 수정하고 도메인 매핑에서 빈 문자열로 처리했다. |
| 내 의견 조회 | Android `PerspectiveApi.kt`는 단일 DTO를 반환하도록 선언했지만 서버 명세는 배열이다. iOS 배열 파싱을 유지한다. |
| 배틀 추천 선택지 | Android DTO의 `label/rationale/philosopher*`는 구형 형태다. 서버와 iOS는 `optionId/position/title/stance/representative/imageUrl`을 사용한다. |
| TTS 완료 호출 | Android는 최종 투표 제출 직전에 호출한다. iOS는 재생 완료 단계에서 호출하며, 서버의 재생 완료 시 호출 계약에 부합한다. |
| 필수 의견 삭제 | 서버는 클래스 설정에 따라 삭제를 거부할 수 있다. iOS는 실패 후 화면을 닫던 동작을 수정해 오류 알림을 표시한다. |
| 초대코드 실패 표시 | Android는 미분류 요청 실패를 일반 토스트로 표시한다. iOS 실기동에서는 인증 재시도 오류의 내부 타입 문자열이 코드 입력 화면에 그대로 노출됐다. `ClassError.unknown` 표시 문구를 일반 요청 오류로 바꿨다. |
| 401 재시도 | Android `TokenAuthenticator`는 재발급 뒤에도 401이면 두 번째 응답에서 재시도를 멈춘다. iOS는 실제 초대코드 조회에서 Alamofire `excessiveRefresh`가 발생했다. 서버가 새 토큰을 거부하는지, 토큰 저장·갱신 경로가 어긋나는지는 추가 인증 증거가 필요하다. |

최신 Android AI 토론·결과 ViewModel은 실제 Repository를 호출한다. Android 결과 카드의 0명 상태는 `아직 참여 없음`과 중립색 도넛을 사용하고, 비율은 응답의 인원수로 계산한다. iOS 결과 화면도 인원수 기반 비율, 0명 문구·중립색 도넛, 참여 설명 문구와 6pt 막대로 맞췄다. 별도 Chrome 탭의 최신 Figma 파일에서 결과 프레임 `13757:17445`를 2026-10-29에 다시 내보내 [`docs/evidence/class-result-figma-20261029.png`](evidence/class-result-figma-20261029.png)에 보관했다. PNG SHA-256 `2720fafbbfb6b68f5d22eaae0cc57851c07e9a636007064eacc7e77954cf8d15`는 2026-10-27 플러그인 추출본과 완전히 같았다. 따라서 이 결과 프레임 자체의 시안은 바뀌지 않았다. 사용자가 준 `2027:2`는 이 파일의 와이어프레임/Hifi 페이지를 열었으며, 그 아래 다른 변경 화면의 전체 추출·대조는 남아 있다.

## 이번 실행 검증

- iPhone 18 Pro (`68DAE7F3-C265-46F4-9FEE-71140108E210`) 대상 `tuist test ClassDomain` 성공. Foundation Models 기기 전용 테스트 4개는 시뮬레이터에서 건너뛰었다.
- 같은 대상 `tuist test Chat`, `tuist test PickeNetwork`, 최종 `tuist build Picke-Stage` 성공. 빌드된 Stage 앱을 시뮬레이터에 설치하고 실행해 클래스 진입 화면까지 확인했다.
- Device Hub에서 앱 홈과 클래스 진입 화면은 표시됐다. `내 클래스` 목록은 재시도 후에도 오류 화면이었고, 앱 로그에서 `GET /api/v1/classes`의 서버 `AUTH_401`을 확인했다. 따라서 제공된 테스트 클래스·초대코드·이용권 코드의 인증된 실제 응답은 확인하지 못했다.
- 최종 설치 앱을 iPhone 18 Pro Device Hub에서 다시 조작했다. `내 클래스`는 오류 화면이었고, `클래스 참여`에서 테스트 초대코드 여섯 글자 입력 및 활성화된 버튼까지 시각 확인했다. 버튼을 누른 실제 `GET /api/v1/classes/join/preview?inviteCode=<redacted>`는 서버 `AUTH_401`로 끝났으며 화면에는 `AuthenticationError.excessiveRefresh`가 포함된 내부 오류가 표시됐다.
- 오류 문구 수정 후 `tuist test ClassDomain`과 `tuist build Picke-Stage`가 성공했다. 새 Stage 앱을 같은 iPhone 18 Pro에 설치·실행해 동일한 초대코드를 다시 요청했다. 응답 실패는 계속됐지만, 화면에는 `클래스 요청을 처리하지 못했습니다. 다시 시도해 주세요.`만 표시되고 내부 오류 문자열은 사라진 것을 Device Hub 접근성 트리와 스크린샷으로 확인했다.
- Android `ClassJoinCodeStep.kt`와 iOS `ClassJoinView.swift`의 코드 입력 UI는 모두 6칸, 대문자 ASCII 입력, 코드 검증 후 이름 입력의 순서다. 실제 Android 실행 화면이나 최신 Figma 캡처가 없어 색·간격·폰트의 일치 여부는 판정하지 않았다.
- Figma 개발 플러그인에는 `2027:2` 하위 화면 검색과 PNG/JSON 내보내기를 추가했고 JavaScript 문법 검사를 통과했다. 별도 Chrome 탭에서 Figma 로그인을 완료하고 결과 프레임 PNG를 다시 내보내 기존 플러그인 PNG와 SHA-256 일치를 확인했다. 새 디자인 전체에 대한 플러그인 실행과 앱 화면의 픽셀 대조는 아직 실행하지 못했다. 사용 중인 원래 탭은 건드리지 않았다.
- API 로그 진단 중 인증 헤더가 그대로 기록되는 문제를 발견해 향후 로그에서 인증 헤더와 인증 API 본문을 가리도록 수정했다. `PickeNetwork` 테스트가 통과했다.
- 2026-10-30에 전체 워크스페이스를 재생성한 뒤 단일 iPhone 18 Pro 목적지로 `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Stage ... build`를 실행해 종료 코드 0을 확인했다. `Class`와 `Picke-Stage`의 `build-for-testing`도 종료 코드 0으로 성공했다.
- 새 Stage 앱을 iPhone 18 Pro에 설치·실행해 다시 확인했다. `GET /api/v1/classes`와 `GET /api/v1/classes/join/preview?inviteCode=<redacted>`가 모두 `dev.picke.store`에서 `401 / AUTH_401`을 반환했다. 초대코드 입력 화면에는 일반 오류 문구만 표시되고 인증 헤더는 로그에서 `<redacted>`로 가려졌다. 이 계정의 클래스 상세·가입·이용권 등록은 진행할 수 없었다.
- `ClassReportTests` 실행은 5분 이상 결과가 없어 중단했다. 한 테스트만 지정한 실행은 종료 코드 0이었으나 결과 번들의 `totalTestCount=0`이라 통과로 간주하지 않는다. 결과 화면 캡처 테스트는 한 번 건너뛰기(`PICKE_CLASS_VISUAL_AUDIT`가 테스트 호스트에 미전달)를 확인했고, 환경변수를 넣은 재실행은 4분 넘게 완료되지 않아 중단했다. 테스트 타깃 컴파일은 성공했지만 실제 캡처와 Figma 픽셀 비교는 미완료다.
- 2026-10-30에 추가 전달된 Figma 노드 `13956:18883`을 감사 플러그인의 기본 내보내기 대상에 추가했다. 별도 Chrome 창의 Figma 내보내기로 `홈` 프레임(375×2010)의 2배율 PNG [`docs/evidence/home-figma-13956-18883-20261030.png`](evidence/home-figma-13956-18883-20261030.png)를 확보했다(750×4020, SHA-256 `6d6741a75f6538fd5d79fef7b193ad89686ce25ffc97702d93d6db0a3f82e99e`). 개발 플러그인은 등록됐지만 Figma Desktop 공유 창이 가로막아 실행·JSON 추출은 확인하지 못했다. 사용 중인 원래 탭과 FESTICORE 창은 변경하지 않았다.
- 동일한 iPhone 18 Pro 설치 앱 로그에서 클래스 API뿐 아니라 출석 체크·주간 출석·읽지 않은 알림도 `AUTH_401`로 끝났다. 따라서 클래스 전용 endpoint 문제보다 현재 저장된 로그인 세션 또는 공통 인증 갱신의 문제일 가능성이 크다. 갱신 요청의 최종 HTTP 응답은 확인되지 않았으므로 원인은 확정하지 않았다.
- iOS 인증 코드와 Android `TokenAuthenticator`·`AuthInterceptor`를 다시 정적 대조했다. Bearer 주입, `POST /api/v1/auth/refresh`와 `X-Refresh-Token`, 새 토큰 저장·공유 인터셉터 갱신 경로에 규약 불일치는 발견하지 못했다. 새 CoreSimulator 로그 조회는 샌드박스 접근 오류로 실패했다. 기존 요청 401 → 갱신 HTTP 상태 → 갱신 뒤 재요청 상태를 비밀값 없이 확보하기 전까지 특정 코드·서버·토큰을 원인으로 단정하지 않는다.
- Device Hub의 iPhone 18 Pro에서 이전에 실제 홈 화면의 헤더·대표 배틀·Best 배틀·하단 탭을 확인했다. 이후 같은 시뮬레이터의 전면 앱이 FESTICORE Design Kit으로 바뀌어 현재 Pické 화면 캡처를 얻지 못했다. 다른 작업을 방해하지 않기 위해 앱 전환·재설치는 하지 않았다. 따라서 새 Figma PNG와 iOS의 픽셀 비교·시각 일치 판정은 미완료다.

## Figma 홈 `13956:18883` 정적 대조 (2026-10-30)

Figma PNG에는 대표 배틀, `지금 뜨는 배틀`, `Best 배틀`, `Best 댓글`, `새로운 배틀`이 순서대로 있다. 현재 iOS `HomeView`는 대표 배틀·뜨는 배틀·Best 배틀·조건부 `오늘의 Pické`·새로운 배틀을 표시하고, 광고를 삽입한다. Android `05c14af`의 `HomeScreen`은 뜨는 배틀이 0건이어도 제목과 빈 카드를 표시하고, 광고를 삽입하며, `오늘의 Pické`는 홈에서 표시하지 않도록 주석 처리했다. Android에도 `Best 댓글` 홈 섹션은 없다. iOS `GET /api/v1/home` 응답 모델과 Android 홈 화면 모델에는 Best 댓글 목록 필드가 없어 실제 데이터 기반으로 시안의 이 섹션을 그릴 수 없다. 화면 데이터가 다른 상태이므로 카드 글자·사진의 픽셀 차이는 UI 구현 결함으로 판정하지 않았다.

## 전달 상태

2026-10-30 GitHub에서 [PR #78](https://github.com/SWYP-Find/Picke-iOS/pull/78)의 `develop` 머지(`1b9ed1d`)와 [PR #79](https://github.com/SWYP-Find/Picke-iOS/pull/79)의 열린 Draft 상태를 다시 확인했다. 현재 작업 트리의 추가 수정은 #79에 반영되지 않았다. 인증 API 성공, Figma 화면 실측 비교, 전체 테스트 실행 및 TestFlight 업로드가 끝나지 않아 이번 추가 작업을 배포 완료로 표시하지 않는다. Claude CLI 계획 검토와 구현 후 점검은 각각 시간 초과로 종료돼 교차 검토 승인 증거도 없다.

## 2026-11-01 재검증과 최신 디자인 추출

- Figma Desktop에서 이 저장소의 `Picke Class Design Audit` 개발 플러그인을 실제 실행했다. 지정된 클래스 5개와 홈 1개의 PNG 및 레이어 JSON 12개 파일을 로컬 `~/Downloads/picke-class-figma-audit.zip`으로 내보냈다. `2027:2` 아래에서 `클래스 참여 · iPhone 18` 프레임 `10052:11290`(402×874)을 검색해 PNG와 JSON을 로컬 `~/Downloads/picke-class-10052-11290.zip`에 저장했다. 전체 레이어 JSON은 공개 GitHub 저장소의 PR에 포함하지 않는다. 단일 화면도 한 ZIP으로 내려받도록 플러그인을 수정해 Figma Desktop의 연속 다운로드 차단을 피했다.
- 추출한 iPhone 18 참여 프레임은 코드 입력을 한 개의 테두리 상자로 그리고 코드 찾기 안내 카드를 둔다. 최신 Android `ClassJoinCodeStep`과 iOS `ClassJoinView`는 6칸 코드 입력을 사용한다. 이 프레임에는 두 개의 하단 CTA가 겹쳐 보여 확정 화면인지 판단할 추가 맥락이 필요하다. 따라서 이 프레임 하나만으로 기존 양 플랫폼의 입력 흐름을 변경하지 않았다.
- 최신 Android `develop` `34448b4`는 홈의 `Best 댓글` 섹션과 nullable `bestComments` 응답 필드를 추가했다. 따라서 위 2026-10-30 대조의 “Android에도 Best 댓글 홈 섹션은 없다”는 문장은 현재 기준으로 유효하지 않다. 서버 `a08c30f`의 `HomeResponse`와 홈 API 명세에는 해당 필드가 없으므로 실데이터 표시 여부는 API 계약 업데이트가 필요하다. 최신 Android 홈에는 `오늘의 Pické` 섹션이 없고, 뜨는 배틀이 0건이어도 빈 상태 카드가 표시된다.
- iPhone 18 Pro 시뮬레이터의 기존 `io.Picke.co` 앱을 실행해 실제 로그인된 홈과 광고 팝업을 캡처했다. Device Hub는 `cgWindowNotFound`로 연결되지 않아 팝업을 닫은 화면 및 클래스 화면의 새 픽셀 대조를 아직 완료하지 못했다. 이 캡처는 새 코드가 빌드·설치된 증거가 아니다.
- 코드 리뷰에서 이용권 코드가 GET 쿼리의 전체 URL 로그에 남는 경로를 확인했다. 네트워크 로그는 URL 경로만 기록하고 인증·클래스·이용권 API의 요청/응답 본문을 가리도록 수정했다. 미분류 내부 오류는 일반 문구로 표시하고, 앱이 명시적으로 만든 사용자 안내는 별도 `userMessage` 타입으로 유지한다.
- `xcodebuild -workspace Picke.xcworkspace -scheme Picke-Stage -configuration Stage -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build -quiet`가 종료 코드 0으로 성공했다. 새 `io.Picke.co` 앱 번들을 iPhone 18 Pro에 설치·실행했고 스플래시 뒤 SNS 로그인 화면으로 이동하는 것을 `simctl` 스크린샷으로 확인했다. 이전 로그인 세션이 유지되지 않아 이 실행에서는 홈·클래스·이용권의 인증된 API와 새 UI를 검증하지 못했다. Device Hub 재연결도 화면 캡처 오류 `-10005`로 실패했다.
- Home Stage 빌드가 성공했고 HomeDomain `HomeRepositoryTests` 4/4, Home 테스트 5/5가 실제 xcresult에서 통과했다. ClassDomain의 `ClassBattleAPIContractTests`와 `ClassErrorMappingTests` 9/9, `ClassMemberAPITests` 3/3, Class `ClassReportTests` 12/12도 통과했다. 첫 ClassReport 실행에서 비율 기대값이 잘못된 테스트 1건을 수정한 뒤 재실행해 12/12를 확인했다.
- Claude CLI 구현 후 교차 점검은 샌드박스 DNS 실패 후 네트워크 제한 밖에서 재시도했으나 180초 시간 초과로 종료됐다. 승인 또는 코드 검토 완료로 간주하지 않는다. PR #79의 새 변경분은 아직 원격 CI를 통과한 상태가 아니며, 인증된 실화면·API 확인과 Figma 픽셀 비교도 남아 있다.
