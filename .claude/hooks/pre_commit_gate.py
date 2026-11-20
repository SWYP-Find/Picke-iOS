"""git pre-commit 훅 본체. 커밋될 index의 코드가 verify 통과 시점과 다르면 커밋을 막는다."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I 실행이라 직접 넣는다
import harness_state as hs  # noqa: E402


def main():
    root = hs.repo_root(".")
    files = hs.staged_unverified(root)
    if not files:
        return 0
    shown = ", ".join(files[:5]) + (f" 외 {len(files) - 5}개" if len(files) > 5 else "")
    sys.stderr.write(f"[검증 게이트] 커밋할 코드가 verify 통과 시점과 다릅니다({shown}).\n"
                     ".claude/scripts/verify로 통과를 확인한 뒤 커밋하세요. 규칙: docs/agent/harness.md\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
