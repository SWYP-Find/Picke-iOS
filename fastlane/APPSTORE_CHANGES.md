# App Store Connect 변경 준비 (2026-11-28)

다음 App Store 제출 때 반영할 항목. 이 문서는 준비용이며 App Store Connect는 아직 바꾸지 않았다.
`bundle exec fastlane release version:'X.Y.Z'`(사용자 지시 때만)가 `fastlane/metadata`를 업로드하면 메타데이터 항목은 함께 반영된다.

| 항목                 | 현재(스토어)                                                              | 바꿀 값                              | 반영 방법                                               |
| -------------------- | ------------------------------------------------------------------------- | ------------------------------------ | ------------------------------------------------------- |
| 앱 아이콘            | 이전 아이콘                                                               | 적갈색 배경 + 흰색 `PicKé` 필기체    | 새 빌드 업로드 시 자동 (`AppIcon.appiconset/1024*.png`) |
| 개인정보처리방침 URL | `https://www.notion.so/3566effee51c81898de5f91d52ab7391?source=copy_link` | `https://picke.store/privacy-policy` | `metadata/ko/privacy_url.txt` (이 PR에서 수정)          |
| 지원 URL             | 개인정보처리방침 Notion 링크와 같음                                       | **결정 필요**                        | `metadata/ko/support_url.txt`                           |
| 설명 · 키워드 · 부제 | 변경 없음                                                                 | 변경 없음                            | —                                                       |

## 근거

- 개인정보처리방침 · 이용약관 URL은 Android 저장소(`SWYP-Find/Picke-Android`)의 `PolicyUrls.kt` 마지막 값
  (`https://picke.store/terms`, `https://picke.store/privacy-policy`, 커밋 `af2739e6`에서 `local.properties`로 이동)과 같다.
  iOS 앱 안 링크(`TermsDocument.urlString` — 약관 동의 시트 · 설정 화면)는 이미 같은 값이라 코드는 바꾸지 않았다.
- `https://picke.store/privacy-policy` 응답 200, 제목 "PicKé 개인정보 처리방침" 확인(2026-11-28).

## 결정이 필요한 것

- 지원 URL: 지금은 개인정보처리방침 페이지를 가리킨다. `picke.store/support` · `/contact`는 401이라 쓸 수 없다.
  문의처가 있는 페이지(예: 문의 이메일 `picke.project@gmail.com`을 적은 페이지) URL을 정하면 `support_url.txt`를 바꾼다.
- 아이콘 원본: 받은 원본이 474×474라 1024로 확대했다. 글자 가장자리가 약간 흐리므로 1024×1024 원본을 받으면 교체한다.
- 설명(`metadata/ko/description.txt`)에 서로 다른 소개문 두 벌이 이어 붙어 있고, 표기가 `PicKé(픽케)`와 `PICKé(피케)`로 섞여 있다.
  바꿀지 정하면 반영한다(이번 PR에서는 손대지 않음).
