#!/bin/bash
# Git 규칙 검사 훅 진입점 (Claude Code PreToolUse · Bash)
#
# 모든 Bash 명령마다 실행된다. git commit / push가 아니면 외부 프로세스 없이 바로 끝낸다(약 10ms).
# 해당하면 check_git_rules.py 한 번으로 모든 검사를 한다. 규칙: docs/agent/git-workflow.md
#
# 직접 실행 (Codex 등 훅이 없는 환경):
#   .claude/hooks/check-git-rules.sh --check-message "feat: 설명 #1"
#   .claude/hooks/check-git-rules.sh --check-branch "feature/ktor-network"

py="$(dirname "$0")/check_git_rules.py"

if [ $# -gt 0 ]; then
  exec python3 -I -S "$py" "$@"
fi

input=$(cat)
case "$input" in
  *git*commit*|*git*push*|*gh*pr*|*hooksPath*) printf '%s' "$input" | exec python3 -I -S "$py" ;;
  *) exit 0 ;;
esac
