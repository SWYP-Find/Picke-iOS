# Pické 유저 액션 이벤트 로깅 설계 (Mixpanel)

> 상태: 설계안 · 기존 `AnalyticsUseCase`(Mixpanel) 확장 · 범위: 핵심 퍼널 + 화면뷰/핵심 액션(큐레이션)

## 1. 목표 & 원칙

- **기존 자산 재사용**: `Projects/Domain/UseCase/Sources/Analytics/AnalyticsUseCase.swift` 의 `AnalyticsUseCase`(TCA `DependencyKey`)를 그대로 확장. 초기화는 `AppDelegate`(`Mixpanel.initialize` + SessionReplay) 유지.
- **카테고리+속성 통합**: 이벤트 이름을 잘게 쪼개지 않고 소수의 이름 + `action`/`type`/`step` 속성으로 구분(분석 용이 + 무료플랜 이벤트 볼륨 관리).
- **볼륨 예산**: 무료플랜은 월 이벤트 수 한도가 있으므로 화면뷰·마이크로 액션은 **핵심만 큐레이션**(모든 탭/스크롤 미추적).
- **프라이버시**: 속성에 PII 금지(이메일 등). 유저 식별은 `userTag` 사용. SessionReplay 민감뷰 마스킹.
- **일관성**: 이벤트/속성 이름은 `snake_case`. 값 enum 은 문자열 rawValue.

## 2. 기존 이벤트 (유지)

| event | 속성 | 발생 지점 |
|---|---|---|
| `sign_up` | method | 로그인 성공(LoginFeature) |
| `battle_step` | step_name(pre_vote/audio_end/post_vote), content_id, choice?, is_changed? | 사전/사후투표, 오디오완료 |
| `community_action` | content_id, comment_length | 댓글 등록 성공 |
| `report_action` | action_type(view/share), top_indicator? | 리포트 조회/공유 |
| `ad_revenue` | placement | 보상형 광고 시청 |

`identify(userID, method)` — 로그인 직후 distinctId 연결 + `people.set(provider)`.

## 3. 신규 이벤트 (Tier 별)

### Tier 1 — 핵심 전환 퍼널 (필수)
| event | 속성 | 발생 지점 |
|---|---|---|
| `onboarding_step` | step(splash / login_shown / kakao_start / terms_shown / terms_agreed / permission_asked / home_entered), method? | 스플래시→로그인→약관→권한→홈 |
| `point_action` | type(attendance_earn / ad_earn / battle_spend), amount, balance? | 출석 +5P / 광고 +10P / 배틀참여 차감 |
| `notification_action` | action(view_list / read_all / item_tap), unread_count? | 알림 진입/모두읽음/항목탭 |
| `share_action` | target(recap / battle / final_vote), channel? | 공유 시트 노출·채널 선택 |

### Tier 2 — 화면뷰 & 버튼/콘텐츠 상호작용 (전면 추적)

> 결정: **전체 화면 + 버튼 탭 전반 추적**(무료 플랜, §Volume 예산 내).

| event | 속성 | 발생 지점 |
|---|---|---|
| `screen_view` | screen, referrer? | **모든 화면** 진입(1 화면 = 1 발화) |
| `content_action` | action, content_id?, section?(best/hot/new/vote) | 홈/콘텐츠 **카드 탭** |
| `ui_action` | action(button 식별자), screen | **버튼 탭 전반**(로그인/투표/공유/CTA/설정/탭바 등) |

> 카드 탭 = `content_action`, 버튼 탭 = `ui_action`. 둘 다 §3.5 유저 컨텍스트 자동 첨부(별도 인자 불필요).
> 화면·버튼을 **전부** 찍으므로 재사용 컴포넌트로 자동화(§5). `ui_action.action` 은 화면별 버튼 식별자를 규약화(`home_notification`, `battle_vote_submit`, `recap_share`, `settings_logout`, `tab_home` …).

`screen_view.screen` 열거(전체): `splash`, `onboarding`, `login`, `home`, `explore`, `quick_battle`, `mypage`, `battle_detail`, `prevote`, `chatroom`, `curation`, `vote_content`, `comment`, `comment_reply`, `notification`, `point`, `settings`, `withdraw`, `recap` … (신규 화면 추가 시 상수 등록).

`content_action.action` 열거: `battle_card_tap`, `hero_tap`, `new_battle_tap`, `vote_card_tap`, `vote_result_view`, `quick_battle_next`(탭 페이징), `explore_category_tap`, `battle_recommend_close`.

### Tier 3 — 마이크로 인터랙션 (선택 · 볼륨 주의, Phase 2)
| event | 속성 | 비고 |
|---|---|---|
| `playback_action` | action(play/pause/skip_15s/replay/seek), content_id | 재생 조작 — 고볼륨, 샘플링/선별 권장 |
| `engagement_action` | action(comment_like / reply_write / comment_report), target_id | 미세 상호작용 |

> Tier 3 는 무료플랜 볼륨을 크게 먹으므로 초기엔 끄거나 핵심(예: skip_15s, comment_like)만.

## 3.5 유저 컨텍스트 자동 주입 (핵심 요구)

> "로그인 한 계정을 보유하고 있다가, 버튼 탭·카드 탭 등 **모든 액션 트리거에 자동으로 넣는다.**"

**결론: 매 `track` 호출마다 유저 ID 를 수동으로 넣지 않는다.** Mixpanel 이 두 메커니즘으로 자동 첨부한다.

1. **`identify(distinctId: userTag)`** — 로그인 성공 직후 1회 호출(이미 LoginFeature 에 있음). 이후 발생하는 **모든 이벤트에 `distinct_id`(=계정)가 자동으로 붙는다.** 사용자별 퍼널/리텐션 분석이 이걸로 성립.
2. **슈퍼 프로퍼티**(`registerSuperProperties`) — 로그인 시 `user_tag`, `login_provider`, `is_logged_in=true`, `philosopher_type` 등을 등록하면 **모든 이벤트 property 에 자동 포함.** 미로그인 상태는 `is_logged_in=false`.

즉 "로그인 정보를 보유했다가 모든 트리거에 넣는" 동작을 **앱이 수동으로 하지 않고 SDK 가 관리**한다(누락·오류 없음). 앱이 별도로 들고 있어야 할 값(예: 다른 로깅에도 재사용)이 있으면 `@Shared` 또는 Dependency 로 `UserContext(userTag, provider, philosopherType)` 를 보관하고, 로그인/로그아웃 시 갱신 → super property 등록/리셋에 사용.

발화 순서(중요):
- **로그인 성공** → `identify(userTag)` → `registerSuperProperties(user_tag/provider/is_logged_in=true/…)` → 이후 이벤트 자동 태깅.
- **로그아웃/탈퇴** → `Mixpanel.reset()` + super property `is_logged_in=false`(계정 분리, 다음 유저와 혼선 방지).
- **앱 시작(로그인 세션 있음)** → 저장된 세션으로 `identify` + super property 재등록.

버튼/카드 탭 이벤트(`content_action`, `ui_action`)도 위 자동 첨부 덕에 **별도 인자 없이** 계정·로그인 컨텍스트를 갖는다.

## 4. 슈퍼 프로퍼티 & 유저 프로퍼티

- **Super properties**(모든 이벤트 자동 첨부, `registerSuperProperties`): `os_type`(**"ios"** / Android 앱은 **"android"**), `app_version`, `build`, `is_logged_in`, `login_provider`.
  - `os_type` 는 **양 플랫폼 동일 키·값 규약**으로 보내야 Mixpanel 에서 iOS/Android 를 한 이벤트로 세그먼트 가능(안드로이드 팀과 키 이름 합의 필수). iOS 앱은 항상 `"ios"` 상수.
- **User properties**(`people.set`): `provider`, `signup_date`(첫 식별 시 `setOnce`), `philosopher_type`, `point_balance`(변동 시 갱신).
- **자동 이벤트**: `trackAutomaticEvents: true` 유지(세션/설치/업데이트 등 Mixpanel 기본).

## 5. 아키텍처 (기존 패턴 유지)

- `AnalyticsEvent` enum 에 위 신규 case 추가(연관값 = 각 Data 구조체), `eventName`/`eventProperties` switch 확장.
- 슈퍼 프로퍼티 등록용 `registerSuperProperties(...)`·유저 프로퍼티용 `setUserProperties(...)` 클로저를 `AnalyticsUseCase` 에 추가(테스트/프리뷰는 no-op).
- 호출은 각 TCA Feature 의 액션 리듀서에서 `@Dependency(\.analyticsUseCase)` 로 `track` — 기존 사이트(PreVote/Comment/ChatRoom/Login/Recap/Profile)와 동일 방식.
- **전면 추적 자동화**(전체 화면·버튼이라 수동 배선은 누락 위험 → 재사용 컴포넌트):
  - `.trackScreen("home")` View modifier — 화면 루트에 부착, `onAppear` 1회 `screen_view` 발화(화면당 1회, 재진입 dedupe).
  - `TrackedButton(action: "recap_share") { … }` 또는 `.trackTap("home_notification")` modifier — 탭 시 `ui_action` 발화 후 원래 액션 실행.
  - 이렇게 하면 각 화면/버튼에 **한 줄**만 추가하면 계정·os_type·슈퍼프로퍼티가 자동으로 붙는다.

## 6. 프라이버시 / SessionReplay

- 속성에 이메일·실명·토큰 금지. 유저 키는 `userTag`.
- SessionReplay 에서 텍스트필드(댓글 입력)·개인정보 화면 마스킹 설정 확인.
- 로그아웃 시 `Mixpanel.mainInstance().reset()` 호출로 distinctId 분리(현재 미적용 → 추가 권장).

## 7. 구현 로드맵

1. **Phase 0**: 슈퍼/유저 프로퍼티 + 로그아웃 `reset()` 추가(기반).
2. **Phase 1(Tier 1)**: onboarding_step / point_action / notification_action / share_action 이벤트 + 발화 배선.
3. **Phase 2(Tier 2)**: screen_view(주요 12화면) + content_action.
4. **Phase 3(Tier 3, 선택)**: playback/engagement — 볼륨 확인 후.

각 Phase 후 Mixpanel Live View 로 이벤트/속성 수신 검증.

## 8. 무료 플랜 볼륨 예산 (중요)

- **무료 = 1M 이벤트/월.** 초과 시 리포트 열람 차단(과금은 없음), 익월 1일 자동 리셋. Session Replay 10K/월.
- **전체 화면 + 버튼 탭**이 볼륨의 대부분을 차지 → 대략 추정: `MAU × 월세션 × (화면뷰 + 버튼탭 per 세션)`.
  - 예) 1,000 MAU × 30 세션 × 20 이벤트 ≈ **60만/월** → 여유. 하지만 3,000 MAU 넘어가면 1M 근접.
- **예산 확보 전략**: Tier 3(`playback_action`/`engagement_action`)는 **초기 off**(가장 고볼륨). 필요 시 skip_15s 등 핵심만.
- 초과 조짐 시: (a) screen_view 를 핵심 화면으로 축소, (b) ui_action 중요 버튼만, (c) Growth 플랜 전환($0.28/1K 수준).
- 결정 완료: **플랜=무료, screen_view=전체 화면, ui_action=버튼 전반.**

## 9. 결정 완료

- **공유 통일**: 모든 공유 = `share_action`(target ∈ recap/battle/final_vote). `report_action` 은 조회(`view`) 전용. → 기존 `RecapFeature` 의 `report_action(share)` 호출은 `share_action(target:recap)` 로 마이그레이션(Phase 1).
- **`trackAutomaticEvents = true` 양 플랫폼 통일**: 자동 이벤트는 세션당 저볼륨이라 유지. Android 도 동일 설정.
