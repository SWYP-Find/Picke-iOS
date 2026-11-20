"""하네스 공용 상태: 코드 변경 판별 · 작업 트리 지문 · 검증 기록. (docs/agent/harness.md)

verify(.claude/scripts/verify) · 커밋 게이트(check_git_rules.py) · 종료 확인(stop_guard.py)이 함께 쓴다.
상태는 .claude/state/(git 제외)에 둔다.
"""
import hashlib
import json
import os
import subprocess
import tempfile
import time

# 검증이 필요한 코드 경로. 문서(.claude/ · *.md)만 바뀌면 검증하지 않는다.
# 앱 · 빌드 경로와 하네스 제어 파일. 하네스 파일을 바꿔도 verify(harness 단계)를 통과해야 커밋된다.
APP_DIRS = ("Projects", "Tuist", "Plugins", "Entitlements")  # Config/는 .gitignore 대상
HARNESS_DIRS = (".claude/hooks", ".claude/scripts", ".githooks")
CODE_DIRS = APP_DIRS + HARNESS_DIRS
CODE_FILES = ("Tuist.swift", "TuistTool.swift", "WorkSpace.swift", "make", "mise.toml", ".swiftformat",
              ".claude/settings.json", ".claude/known-test-failures.txt")
HARNESS_FILES = (".claude/settings.json", ".claude/known-test-failures.txt")
# fastlane이 배포 때마다 빌드 번호를 고치고 커밋하지 않는 파일. 검증 대상에서 뺀다.
LOCAL_ONLY = ("Plugins/ProjectTemplatePlugin/ProjectDescriptionHelpers/Project+Templete/Extension+String.swift",)
STATE_DIR = os.path.join(".claude", "state")
VERIFY_FILE = os.path.join(STATE_DIR, "verify.json")
HOOK_MARK = "# picke-harness pre-commit"
DELETED = "deleted"
MAX_FAILURES = 2  # 같은 단계가 이 횟수만큼 연속 실패하면 사용자에게 보고한다


def git(root, *args, env=None):
    return subprocess.run(
        ["git", "-C", root, *args], capture_output=True, text=True, env=env, check=True, timeout=30
    ).stdout


def under(path, prefixes):
    return any(path == p or path.startswith(p + "/") for p in prefixes)


def is_code(path):
    if path.endswith(".md") or path in LOCAL_ONLY:
        return False
    return path in CODE_FILES or under(path, CODE_DIRS)


def is_harness(path):
    return path in HARNESS_FILES or under(path, HARNESS_DIRS)


def repo_root(start):
    return git(start, "rev-parse", "--show-toplevel").strip()


def base_ref(root):
    """비교 기준: develop과 갈라진 지점. 원격이 없으면 로컬 develop."""
    for ref in ("origin/develop", "develop"):
        try:
            return git(root, "merge-base", "HEAD", ref).strip()
        except subprocess.CalledProcessError:
            continue
    return "HEAD"


def changed_code_files(root):
    """develop 이후 바뀐 코드 파일(커밋 · 스테이징 · 작업 중 · 새 파일 모두)."""
    # -z: 한글 등 비ASCII 경로가 따옴표 · 이스케이프로 바뀌지 않게 한다
    tracked = git(root, "diff", "--name-only", "-z", base_ref(root)).split("\0")
    untracked = git(root, "ls-files", "-z", "--others", "--exclude-standard").split("\0")
    return sorted({p for p in tracked + untracked if p and is_code(p)})


def fingerprint(root):
    """작업 트리의 코드 파일 내용 지문. 커밋으로 나눠 담아도 내용이 같으면 같은 값이다."""
    return hashlib.sha256("\n".join(working_code(root)).encode()).hexdigest()


def code_entries(root):
    """작업 트리의 코드 파일 {경로: "모드 blob"}. HEAD에 있는데 지운 파일은 DELETED. pre-commit 훅이 index와 대조한다."""
    entries = {}
    for line in working_code(root):
        meta, path = line.split("\t", 1)
        mode, _, sha = meta.split()
        entries[path] = f"{mode} {sha}"
    head = git(root, "ls-tree", "-r", "-z", "--name-only", "HEAD", "--", *CODE_DIRS, *CODE_FILES) if has_head(root) else ""
    for path in head.split("\0"):
        if path and path not in entries and is_code(path):
            entries[path] = DELETED
    return entries


def has_head(root):
    try:
        git(root, "rev-parse", "--verify", "-q", "HEAD")
        return True
    except subprocess.CalledProcessError:
        return False


def working_code(root):
    fd, index = tempfile.mkstemp(prefix="harness-index-")
    os.close(fd)
    try:
        os.unlink(index)  # 실제 index를 복사하면 같은 크기 · 같은 시각 수정을 stat 캐시로 놓친다. 매번 새로 해시한다(약 1.5초)
        env = dict(os.environ, GIT_INDEX_FILE=index)
        git(root, "add", "-A", "--", *present_code_paths(root, env), env=env)
        tree = git(root, "write-tree", env=env).strip()
        listing = git(root, "ls-tree", "-r", "-z", tree, "--", *CODE_DIRS, *CODE_FILES).split("\0")
        return [line for line in listing if line and is_code(line.split("\t", 1)[1])]  # 문서 · 배포 전용 파일은 지문에서 뺀다
    finally:
        if os.path.exists(index):
            os.unlink(index)


def present_code_paths(root, env=None):
    """디스크에 있거나 index에 남은 코드 경로. 지운 루트 파일도 넣어야 삭제가 반영된다."""
    tracked = [p for p in git(root, "ls-files", "-z", "--", *CODE_DIRS, *CODE_FILES, env=env).split("\0") if p]
    return [p for p in CODE_DIRS + CODE_FILES
            if os.path.exists(os.path.join(root, p)) or any(under(t, (p,)) for t in tracked)]


def load(root):
    try:
        with open(os.path.join(root, VERIFY_FILE), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save(root, state):
    os.makedirs(os.path.join(root, STATE_DIR), exist_ok=True)
    state["at"] = time.strftime("%Y-%m-%dT%H:%M:%S")
    with open(os.path.join(root, VERIFY_FILE), "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def unverified(root):
    """검증이 필요한데 마지막 통과 기록과 지문이 다르면 바뀐 코드 파일 목록을 돌려준다."""
    files = changed_code_files(root)
    if not files:
        return []
    state = load(root)
    if state.get("passed") and state.get("fingerprint") == fingerprint(root):
        return []
    return files


def staged_unverified(root):
    """커밋될 index(GIT_INDEX_FILE 포함)의 코드 변경 중 verify 통과 시점과 내용이 다른 경로."""
    staged = [p for p in git(root, "diff", "--cached", "--name-only", "--no-renames", "-z").split("\0") if p and is_code(p)]
    if not staged:
        return []
    state = load(root)
    if not state.get("passed") or "code" not in state:
        return staged  # 통과 기록이 없으면 삭제만 담은 커밋도 막는다
    verified = state["code"]
    index = {}
    for line in git(root, "ls-files", "-s", "-z", "--", *staged).split("\0"):
        if line:
            meta, path = line.split("\t", 1)
            mode, sha, _ = meta.split()
            index[path] = f"{mode} {sha}"
    return [p for p in staged if index.get(p, DELETED) != verified.get(p)]  # 삭제는 verify 때도 지워져 있어야 한다


def install_git_hooks(root):
    """현재 hooks 폴더(core.hooksPath 그대로)에 .githooks/pre-commit을 부르는 심을 만든다.

    hooksPath를 바꾸지 않는다. 같은 폴더의 Git LFS 훅과 commit-msg 정리 훅이 계속 돌아야 한다.
    다른 pre-commit 훅이 이미 있으면 덮어쓰지 않고 이유를 돌려준다. 부르는 쪽(verify · 커밋 게이트)은 이때 실패한다.
    """
    hooks_dir = git(root, "rev-parse", "--path-format=absolute", "--git-path", "hooks").strip()
    path = os.path.join(hooks_dir, "pre-commit")
    if os.path.exists(path):
        with open(path, encoding="utf-8", errors="replace") as f:
            if HOOK_MARK in f.read():
                return ""
        return (f"{path}에 다른 pre-commit 훅이 있어 검증 게이트를 설치하지 못했습니다. 그 훅에서 .githooks/pre-commit을 부르게 "
                f"합치고 '{HOOK_MARK}' 줄을 넣은 뒤 다시 실행하세요. (docs/agent/harness.md)")
    os.makedirs(hooks_dir, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(f"#!/bin/sh\n{HOOK_MARK} (docs/agent/harness.md)\n"
                'exec "$(git rev-parse --show-toplevel)/.githooks/pre-commit" "$@"\n')
    os.chmod(path, 0o755)
    return ""
