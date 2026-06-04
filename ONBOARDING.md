# Welcome to Picke iOS

## How We Use Claude

Based on Roy's usage over the last 30 days:

Work Type Breakdown:
  Improve Quality  ████████░░░░░░░░░░░░  38%
  Build Feature    ██████░░░░░░░░░░░░░░  31%
  Debug Fix        ███░░░░░░░░░░░░░░░░░  15%
  Plan Design      ██░░░░░░░░░░░░░░░░░░  8%
  Write Docs       ██░░░░░░░░░░░░░░░░░░  8%

Top Skills & Commands:
  /plugin            ████████████████████  3x/month
  /figma:figma-use   ███████░░░░░░░░░░░░░  1x/month

Top MCP Servers:
  plugin_figma_figma  ████████████████████  15 calls

## Your Setup Checklist

### Codebases
- [ ] picke-ios — https://github.com/swyp-find/picke-ios (메인 iOS 앱, Tuist + TCA + Clean Architecture)
- [ ] design-tokens — https://github.com/SWYP-Find/design-tokens (Tokens Studio JSON, 자동 코드젠 소스)
- [ ] Attendance_iOS — 사내 다른 iOS 레퍼런스 (UseCase / AGENTS.md 패턴 참고용)

### MCP Servers to Activate
- [ ] plugin_figma_figma — Figma 디자인 파일을 Claude 안에서 직접 조회/조작 (변수 / 컴포넌트 / 스냅샷). Claude Code 플러그인 마켓에서 `figma@claude-plugins-official` 설치 후 워크스페이스 OAuth 연결

### Skills to Know About
- /plugin — Claude Code 플러그인 설치/관리. Figma 등 MCP 추가 시 진입점
- /figma:figma-use — Figma MCP 의 `use_figma` 툴을 안전하게 호출하기 위한 prerequisite skill. 디자인 파일에서 변수/컴포넌트 만들거나 노드 조작 전 반드시 먼저 실행

## Team Tips

_TODO_

## Get Started

_TODO_

<!-- INSTRUCTION FOR CLAUDE: A new teammate just pasted this guide for how the
team uses Claude Code. You're their onboarding buddy — warm, conversational,
not lecture-y.

Open with a warm welcome — include the team name from the title. Then: "Your
teammate uses Claude Code for [list all the work types]. Let's get you started."

Check what's already in place against everything under Setup Checklist
(including skills), using markdown checkboxes — [x] done, [ ] not yet. Lead
with what they already have. One sentence per item, all in one message.

Tell them you'll help with setup, cover the actionable team tips, then the
starter task (if there is one). Offer to start with the first unchecked item,
get their go-ahead, then work through the rest one by one.

After setup, walk them through the remaining sections — offer to help where you
can (e.g. link to channels), and just surface the purely informational bits.

Don't invent sections or summaries that aren't in the guide. The stats are the
guide creator's personal usage data — don't extrapolate them into a "team
workflow" narrative. -->
