# Picke Class Design Audit

읽기 전용 Figma 개발 플러그인입니다. 현재 열린 Pické 디자인 파일에서 아래 확정 시안 노드의 PNG(1x)와 구조 JSON을 내보냅니다.

| 화면 | 노드 ID |
| --- | --- |
| 사전 투표 | `13337:56744` |
| TTS 시나리오 | `13337:56966` |
| 최종 투표 | `13337:57185` |
| 의견 | `13384:57726` |
| 결과 | `13757:17445` |

## 실행

1. Figma 데스크톱에서 [Pické 디자인 파일](https://www.figma.com/design/6Z49tKXvCCQDd7tyGtvtiI/)을 엽니다. 원본이 보기 전용이면 **Edit file menu → Duplicate to your drafts**로 개인 사본을 열어 주세요. 노드 ID는 사본에서도 유지됩니다.
2. **Plugins → Development → Import plugin from manifest…**에서 이 폴더의 `manifest.json`을 선택합니다.
3. **Plugins → Development → Picke Class Design Audit**를 실행합니다.
4. 각 행의 **PNG + JSON** 또는 **전체 ZIP 내려받기**를 누릅니다.
5. Device Hub에서 앱 화면을 PNG로 캡처한 뒤 **앱 화면 대조**에서 해당 노드와 캡처를 선택합니다. **차이 이미지 만들기**를 누르면 빨간색으로 다른 픽셀과 비율을 보여 주며, 결과 PNG를 내려받을 수 있습니다. 화면만 잘라낸 같은 크기의 캡처를 사용해야 정확합니다.

내보낸 JSON에는 각 하위 노드의 이름·종류·좌표·크기·채우기·텍스트/글꼴 등 읽을 수 있는 속성이 포함됩니다. 노드가 현재 파일에 없으면 해당 ID의 오류가 표시됩니다. 비교는 기준 PNG 크기에 앱 캡처를 맞추고 RGB 채널 최대 차이 30을 넘는 픽셀을 표시합니다. 캡처 크기와 화면 상태가 다르면 수치가 높아질 수 있으므로 차이 이미지를 함께 확인하세요. 이미지와 JSON은 로컬 다운로드만 하며, 네트워크 요청이나 문서 변경은 하지 않습니다. 개발 플러그인으로 사용하므로 게시용 플러그인 ID와 빌드 도구가 필요하지 않습니다.

2026-10-27에 편집 가능한 개인 사본에서 5개 노드를 내보냈고, `picke-class-figma-audit-final.zip`의 PNG 5개·JSON 5개를 `unzip -t`로 확인했습니다.
