# 클래스 기능 Android 동일화 (2026-11-20, iOS 2차 QA 대응)

기준: `SWYP-Find/Picke-android` `6fbdf86` (`presentation/src/main/java/com/picke/presentation/ui/classroom/` 이하 경로).
QA: 시트 "2차_iOS QA" 실패·보류 항목.

| QA | Android 근거 | iOS 변경 |
|---|---|---|
| 02 이름 수정 화면 안 뜸 | `classdetail/ClassDetailViewModel.kt:69,77` 마감일 "수정"·"클래스 정보 수정" 모두 `NavigateToEdit` / `classedit/ClassEditViewModel.kt:115` PATCH 1회(이름 항상, 마감일은 바뀐 경우만) | `ClassDetailFeature` `.openEdit` → `ClassCoordinator`가 `classEdit` push, 저장 뒤 상세 재조회. `ClassroomService.updateClass` + `ClassRoomInterface.updateClass` 추가, `ClassEditFeature`는 PATCH 1회 |
| 07 운영자 참여 인원 숫자 | `classmember/ClassMemberScreen.kt:112` "멤버 %d" = 명단 수, `classdetail/ClassDetailScreen.kt:176`·`myclass/component/MyClassCard.kt:128` = `memberCount` | `ClassMemberFeature.memberCountTitle` = `members.count`(정원 표기 제거), 상세·목록 카드는 `memberCount` |
| 08 마감 표시 | `classdetail/ClassDetailScreen.kt:251` 진행 중 SECONDARY / 종료 TERTIARY, `ClassDetailViewModel.kt:134,138` 마감·미참여 토스트, `ClassDetailScreen.kt:326` 버튼 두 개 항상 노출 | 상세 배지 스타일 분리, "배틀 참여" 항상 노출 + "참여 기간이 마감되었어요." / "운영자 참여를 켜지 않은 클래스라 배틀에 참여할 수 없어요." 토스트, "결과 보기"는 역할과 무관하게 결과 화면 |
| 12 공유 화면 입장·카테고리 | `classshare/ClassShareViewModel.kt:70`·`ClassDetailViewModel.kt:108` 상세+`/battle` 병렬 조회, `component/ClassManageSheet.kt:93` 공유 행 → ClassShare, `ClassNavGraph.kt:82` "클래스로 이동하기" → 내 클래스 | `ClassRoom.applyingBattle` 로 카테고리·입장·소요 시간 채움(상세·공유·수정), 관리 시트 공유 행 → 공유 화면(멤버에게도 관리 시트·나가기), 공유 문구 Android `class_share_code_message` |
| 13 멤버 목록에 운영자 없음 | `classmember/ClassMemberViewModel.kt` 서버 `/members` 그대로 표시 | 클라이언트 차이 없음 → 변경 없음(서버 응답 확인 필요) |
| 20 입장분포 그래프·디자인 | `classresult/component/ClassResultAiInsightCard.kt:42` 분홍 카드(근거 목록 없음), `classresult/component/ClassResultStanceCard.kt:156` 도넛, `classresult/model/ClassResultInsightUiModel.kt:15` 주요 의견은 두 댓글이 모두 있을 때만 | 새 `ClassResult` 화면(`Feature/Class/Sources/ClassResult`) — 운영자·멤버 공용 |
| 21 리포트 구조 | `classresult/ClassResultViewModel.kt:88` 탭 조건, `classresult/model/ClassResultUiState.kt:25` 탭 바는 두 탭 모두 있을 때만, `ClassResultMyVoteCard.kt:64` 입장 변경 배지, `ClassResultFeedbackItemUiModel.kt:15` 고정 제목 3개, `ClassResultFeedbackCard.kt:118` "내가 남긴 의견 N개 보기" | `ClassResultFeature`/`ClassResultView`, 상태 보존 모델 `ClassResultInsightBoard`·`ClassResultMyReportBoard` |
| 25 내보낸 사용자 메인 이동 | classroom 패키지에 강제 이동 처리 없음(`classjoin/ClassJoinViewModel.kt` 다이얼로그만) | Android 와 동일하므로 변경 없음(기획 확인 필요) |
| 27 AI 답변 대기 중 삭제 문구 | `classdebate/ClassDebateViewModel.kt:83` 조회 실패 "정보를 불러오지 못했어요", `:119` 요청 실패 "요청을 처리하지 못했어요" 토스트 | `ClassAIChatFeature` 서버 실패를 같은 토스트 문구로 표시 |
| 1차 20 댓글 추가 입력창 | — | 2차 14번 "추가 댓글 등록" 통과 → 변경 없음 |

기타: 상세 삭제·나가기 뒤 내 클래스 목록으로 돌아가 갱신(`ClassDetailViewModel.kt:178` `NavigateBackAfterClassRemoved`).

## Codex 교차 점검 (codex-cli 0.170.0, effort xhigh, 판정 REVISE)

| ID | 지적 | Android 대조 | 처리 |
|---|---|---|---|
| RESULT-01 | 주요 의견 항상 숨김 | `classresult/model/ClassResultInsightUiModel.kt` best·mostDebated 가 TODO 로 `""` → 항상 숨김 | 유지(동일) |
| RESULT-02 | 인사이트 재시도 후 재조회 없음 | `ClassResultViewModel.retryInsight` 응답 1회만 반영 | 유지(동일) |
| RESULT-03 | 사후 선택이 없어도 입장 변경 배지 | `ClassResultReportUiModel.isStanceChanged` = `pre != post`(nil→`""`) | 유지(동일) |
| RESULT-04 | 실패 후 재시도 없음 | `ClassResultScreen` 실패 시 `PickeLoadFailedSection` 만 | 유지(동일) |
| RESULT-05 | 보드 하나 실패 시 전체 실패 | `fetchClassResult` 인사이트·내 리포트 실패 시 전체 실패 | 유지(동일) |
| PLAN-01 | QA 25 기준 미정 | Android 도 처리 없음 | 기획 결정 필요 |

코드 변경으로 이어진 지적은 없어 재점검은 하지 않았다.
