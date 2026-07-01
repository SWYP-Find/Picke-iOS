# Pické Mixpanel 이벤트 명세 (크로스플랫폼 계약서)

> 대상: **Android / iOS 공통**. 두 플랫폼이 **동일한 이벤트명·속성키·값**으로 전송해야 Mixpanel 에서 하나의 이벤트로 세그먼트/비교가 됩니다.
> 이 문서가 계약(source of truth)입니다. 변경 시 양 플랫폼 동시 반영.

## 0. 필수 규약 (반드시 준수)

- 이벤트명·속성키·enum 값은 **모두 `snake_case` 소문자**. 임의 변형 금지.
- 모든 이벤트에 **슈퍼 프로퍼티**(§3)가 자동 첨부되어야 함 → `registerSuperProperties`.
- 로그인 성공 시 **`identify(distinctId = user_tag)`** 호출(계정 단위 분석의 기준). 이후 모든 이벤트에 계정이 자동 연결됨.
- **로그아웃/탈퇴 시 `reset()`** 호출 + 슈퍼프로퍼티 `is_logged_in=false`.
- 속성에 **PII 금지**(이메일/실명/토큰). 유저 키는 `user_tag`.
- 플랫폼 구분은 `os_type` 슈퍼프로퍼티(`"ios"` / `"android"`)로만. 이벤트명에 플랫폼 넣지 말 것.
- **`trackAutomaticEvents = true`** 로 **양 플랫폼 통일**(초기화 시). 자동 이벤트(세션/설치/업데이트)는 세션당 저볼륨 → 무료 한도 부담 적고 리텐션 분석에 유용.
- **모든 공유는 `share_action`** 로 통일. `report_action` 은 리포트 **조회(view)** 전용.

## 1. 이벤트 목록 (name → 속성 → 허용값)

### 핵심 퍼널
| event | 속성(키: 타입) | 허용값 / 비고 |
|---|---|---|
| `sign_up` | method: string | 최초 가입 완료 시 1회 |
| `battle_step` | step_name: string, content_id: string, choice?: string, is_changed?: bool | step_name ∈ `pre_vote` `audio_end` `post_vote`. is_changed 는 post_vote 에서만 |
| `community_action` | content_id: string, comment_length: int | 댓글 등록 성공 |
| `report_action` | action_type: string, top_indicator?: string | action_type = `view` 만(리포트 **조회**). **공유는 `share_action` 사용**(아래) |
| `ad_revenue` | placement: string | 보상형 광고 시청 완료 |
| `onboarding_step` | step: string, method?: string | step ∈ `splash` `login_shown` `kakao_start` `terms_shown` `terms_agreed` `permission_asked` `home_entered` |
| `point_action` | type: string, amount: int, balance?: int | type ∈ `attendance_earn` `ad_earn` `battle_spend` |
| `notification_action` | action: string, unread_count?: int | action ∈ `view_list` `read_all` `item_tap` |
| `share_action` | target: string, channel?: string | target ∈ `recap` `battle` `final_vote`. **모든 공유는 이 이벤트로 통일**(recap 리포트 공유 포함) |

### 화면 / 상호작용 (전면 추적)
| event | 속성(키: 타입) | 허용값 / 비고 |
|---|---|---|
| `screen_view` | screen: string, referrer?: string | screen = §2 화면 enum. 화면당 1회(재진입 시 재발화 OK, 화면 내 중복 금지) |
| `content_action` | action: string, content_id?: string, section?: string | action ∈ `battle_card_tap` `hero_tap` `new_battle_tap` `vote_card_tap` `vote_result_view` `quick_battle_next` `explore_category_tap` `battle_recommend_close`. section ∈ `best` `hot` `new` `vote` |
| `ui_action` | action: string, screen: string | action = 버튼 식별자(§2.1 규약). 카드 탭은 `content_action` 사용 |

### 마이크로 (Tier 3, **초기 비활성** — 볼륨 큼, 합의 후 켬)
| event | 속성 | 허용값 |
|---|---|---|
| `playback_action` | action: string, content_id: string | action ∈ `play` `pause` `skip_15s` `replay` `seek` |
| `engagement_action` | action: string, target_id: string | action ∈ `comment_like` `reply_write` `comment_report` |

## 2. `screen_view.screen` enum (전체)

`splash` `onboarding` `login` `home` `explore` `quick_battle` `mypage` `battle_detail` `prevote` `chatroom` `curation` `vote_content` `comment` `comment_reply` `notification` `point` `settings` `withdraw` `recap`

> 신규 화면 추가 시 이 목록에 상수 등록 후 양 플랫폼 반영.

### 2.1 `ui_action.action` 버튼 식별자 규약

`{screen}_{button}` 형식. 예:
`home_notification`, `home_more_best`, `battle_vote_submit`, `prevote_start`, `chatroom_play`, `curation_close`, `recap_share`, `settings_logout`, `settings_withdraw`, `point_charge`, `notification_read_all`, `tab_home` `tab_explore` `tab_quick_battle` `tab_mypage`

> 새 버튼은 같은 규약으로 추가하고 이 문서에 등재.

## 3. 슈퍼 프로퍼티 (모든 이벤트 자동 첨부)

`registerSuperProperties` 로 등록. 로그인/앱시작 시 갱신.

| 키 | 값 | 비고 |
|---|---|---|
| `os_type` | `"ios"` / `"android"` | 플랫폼 상수 |
| `app_version` | 예: `"1.0.3"` | 마케팅 버전 |
| `build` | 예: `"20"` | 빌드 번호 |
| `is_logged_in` | bool | 로그인 여부 |
| `login_provider` | 예: `"kakao"` | 로그인 시 등록, 로그아웃 시 제거 |

## 4. 유저 프로퍼티 (`people.set`)

| 키 | 값 | 비고 |
|---|---|---|
| `provider` | `"kakao"` … | |
| `signup_date` | ISO8601 | **`setOnce`**(최초 1회) |
| `philosopher_type` | 철학자 유형 | 산출 시 갱신 |
| `point_balance` | int | 변동 시 갱신 |

## 5. Android 구현 힌트 (Mixpanel Android SDK)

```kotlin
// 초기화 (Application.onCreate)
val mixpanel = MixpanelAPI.getInstance(context, BuildConfig.MIXPANEL_TOKEN, trackAutomaticEvents = true)

// 로그인 성공
mixpanel.identify(userTag)
mixpanel.registerSuperProperties(JSONObject().apply {
    put("os_type", "android")
    put("app_version", BuildConfig.VERSION_NAME)
    put("build", BuildConfig.VERSION_CODE.toString())
    put("is_logged_in", true)
    put("login_provider", provider)
})
mixpanel.people.identify(userTag)
mixpanel.people.setOnce(JSONObject().apply { put("signup_date", isoNow) })
mixpanel.people.set(JSONObject().apply { put("provider", provider) })

// 이벤트 전송 (예: 버튼 탭)
mixpanel.track("ui_action", JSONObject().apply {
    put("action", "recap_share")
    put("screen", "recap")
})

// 화면 진입
mixpanel.track("screen_view", JSONObject().apply { put("screen", "home") })

// 로그아웃
mixpanel.registerSuperProperties(JSONObject().apply { put("is_logged_in", false) })
mixpanel.reset()
```

> iOS 는 동일 스키마를 `Mixpanel.mainInstance().track(event:properties:)` 로 전송. **키/값 문자열이 100% 일치**해야 함.

## 6. 검증

- Mixpanel **Live View / Events** 에서 iOS·Android 이벤트가 같은 이름·속성으로 들어오는지 확인.
- 한 계정으로 두 기기 접속 시 `distinct_id` 가 동일(`user_tag`)해 유저 단위로 합쳐지는지 확인.

## 7. 무료 플랜 주의

- 무료 = **1M 이벤트/월**(양 플랫폼 합산). 초과 시 리포트 열람 차단(익월 리셋).
- Tier 3(`playback_action`/`engagement_action`)는 볼륨이 커서 **초기 비활성**. 켜기 전 양 팀 합의.
