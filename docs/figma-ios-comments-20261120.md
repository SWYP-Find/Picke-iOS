# Figma "클래스 복제본" IOS 페이지 댓글 반영 (2026-11-20)

기준: `SWYP-Find/Picke-android` `6fbdf86` (`presentation/src/main/` 이하 경로).
댓글은 Figma 데스크톱 앱 댓글 패널에서 읽었다. IOS 댓글은 12개이며, 화면 캡처가 가리키는 위치는 아래 표의 "화면"이다.

| # | 댓글 | 화면 | Android 근거 | iOS 변경 |
|---|---|---|---|---|
| 1 | 위 안내를 펼친 뒤 아래 안내를 펼치면 애니메이션 이상 | 이용권 코드 입력 | `ui/my/ticket/ticketregister/component/TicketCodeGuideItem.kt:40` 항목마다 독립 `isExpanded` | `ClassTicketFeature.expandedFAQs: Set<Int>`, 하나를 펼쳐도 다른 항목은 그대로 |
| 2 | 카테고리 미선택 시 "조건에 맞는 콘텐츠 보기" 비활성 | 새 클래스 조건 | `ui/classroom/classcreate/model/ClassCreateUiState.kt:43` CONDITION 은 `selectedCategories.isNotEmpty()` | `ClassTopicFeature.State.canSearch`, 버튼 `.disabled`, `searchTapped` 가드 |
| 3 | 입력 칸 문구 "전달 받은 코드를 입력해주세요" | 이용권 코드 입력 | `res/values/strings.xml:99` `ticket_register_code_placeholder` | `ClassTicketView` placeholder |
| 4 | 도움말 디자인 상이 | 이용권 확인 | `ui/my/ticket/ticketregister/component/TicketRegisterNoticeCard.kt` 분홍 배경·테두리·확성기 아이콘 | `registerNoticeCard()`, `megaphone` 에셋(`ic_megaphone`) |
| 5 | 뒤로가기 시 화면 위치 이상 | 이용권 코드 입력(키보드) | `TicketRegisterReducer.kt` BackClick: CONFIRM → CODE | 뒤로가기 전에 키보드를 내리고, 단계가 바뀌면 스크롤을 처음 위치로(`.id(phase)`) |
| 6 | 오류별 카드 디자인 다름 | 이용권 오류 안내 | `TicketRegisterScreen.kt:111` 이미 등록 → `PickeConfirmDialog`, 그 외 → `PickeSingleActionDialog` | `noticeReversed` = `pickeConfirmDialog`, 새 `singleAction` 스타일(이용권 안내·이용권 필요 안내) |
| 7 | 등록 기한 행 불필요 | 이용권 확인 | `ui/my/ticket/component/TicketCard.kt` 행: 참여 인원·이용 기간·클래스 생성 | "등록 기한" 행 제거 |
| 13 | 아이콘 다름 | 클래스 관리 시트 | `ui/classroom/component/ClassManageSheet.kt:81-109` `ic_edit`·`ic_arrow_up_right`·`ic_trash`·`ic_log_out`, `:141` 40 원·24 아이콘, `:173` `ic_arrow_right` 16 | SF Symbol → 에셋(`edit`·`arrowUpRight`·`trash`·`logOut`·`arrowRight`) |
| 14 | 바텀 시트 누락 | 생성 방식 선택 | `classcreate/component/ClassMethodCard.kt:53` 배지 전체 `onBadgeClick` → `ClassMethodGuideSheet` | 배지 전체를 안내 시트 탭 영역으로(기존엔 ⓘ 주변만 반응) |
| 15 | 미리듣기 디자인 상이 | 1분 미리듣기 | `classbattlepreview/ClassBattlePreviewScreen.kt` `ScenarioChatBubble`·`AudioPlayerBar`, `component/ClassBattlePreviewBadge.kt`, `model/ClassBattlePreviewUiState.kt` `visibleScripts` | 채팅방과 같은 말풍선(아바타·이름 묶음, 비활성 흐림, 이퀄라이저), 나온 대사만 표시, `PickeAudioPlayerBar`, 배지 스타일 |
| 18 | 중간에 나가도 음성이 계속 들림 | 추천 배틀 → 미리듣기 | `ClassBattlePreviewViewModel.kt:89` ScreenStop → pause | 재생 명령을 `CancelID.playback` 하나로 묶고, 나갈 때 먼저 취소한 뒤 일시정지 |
| 19 | 배속 디자인 안드로이드와 상이 | 1분 미리듣기 | `ClassBattlePreviewReducer.kt:15` 탭마다 `PLAYBACK_SPEEDS`(`ui/component/AudioPlayerBar.kt:39` 1.0·1.5·2.0·3.0) 순환 | 메뉴 대신 탭 순환(`nextPlaybackRate`) |

남은 것: 클래스 배틀 진행 화면(`ClassBattleFlowView`)의 배속은 아직 메뉴(`AudioPlayerControlView`)를 쓴다. 이번 댓글 범위 밖이라 바꾸지 않았다.
