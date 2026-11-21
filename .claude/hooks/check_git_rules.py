"""Git 규칙 검사 (docs/agent/git-workflow.md). check-git-rules.sh가 git commit / push가 보일 때만 호출한다.

  1) 보호 브랜치(main, develop, release)에 직접 커밋 · 푸시 금지, main · develop · release 삭제 금지
  2) 작업 브랜치 이름: {종류}/{요약} (종류: feature · fix · hotfix · refactor · chore · docs · test · ci · release)
  3) 커밋 제목: 한국어 한 줄, 50자 이하, 마침표로 끝내지 않음 ([FEAT]: · feat: 머리말과 #이슈번호는 선택)
  4) .DS_Store 커밋 금지
  5) 커밋 메시지 · PR 본문에 Co-Authored-By: Claude · Generated with Claude 줄 금지
  6) pre-commit 검증 게이트 우회 금지(--no-verify · -n · core.hooksPath 변경 · git 별칭 정의)

위반하면 stderr에 이유를 쓰고 exit 2 → Claude Code가 명령을 막는다.
직접 실행: python3 check_git_rules.py --check-message "로그인 화면 추가" / --check-branch "feature/login"
"""
import json
import os
import re
import shlex
import subprocess
import sys

BRANCH_KINDS = "feature|fix|hotfix|refactor|chore|docs|test|ci|release"
BRANCH_RE = re.compile(rf"^(?:{BRANCH_KINDS})/[A-Za-z0-9#][A-Za-z0-9#._-]*$")
PROTECTED = {"main", "develop", "release"}
HANGUL_RE = re.compile(r"[가-힣]")
SQUASH_SUFFIX_RE = re.compile(r" \(#[0-9]+\)$")

GIT_OPTS = r"(?:\s+(?:-C|-c|--git-dir|--work-tree)\s+\S+|\s+-\S+)*"   # git -C 경로 commit 등
# 명령이 시작되는 자리(처음 · && · || · ; · | · 줄바꿈 · $( · ( 뒤)에 오는 git만 실제 명령으로 본다.
# echo "git commit" 같은 문자열이나 heredoc 본문 속 문장은 검사하지 않는다.
CMD_START = r"(?:^|&&|\|\||;|\||\n|\$\(|\()\s*(?:\w+=\S+\s+)*"
COMMIT_RE = re.compile(CMD_START + r"git" + GIT_OPTS + r"\s+commit(?:\s|$)")
PUSH_RE = re.compile(CMD_START + r"git" + GIT_OPTS + r"\s+push(?:\s|$)")
SEPARATOR_RE = re.compile(r"&&|\|\||;|\||\n")
# refs/heads/develop 같은 전체 ref 이름도 같은 브랜치로 본다
PROTECTED_REF = r"(?:refs/heads/)?(?:main|develop|release)"
PUSH_DELETE_RE = re.compile(r"(?:--delete|-d)\s.*\b(?:main|develop|release)\b|\s\+?:" + PROTECTED_REF + r"(?:\s|$)")
PUSH_PROTECTED_RE = re.compile(r"[\s:+]" + PROTECTED_REF + r"(?:\s|$)")
HEREDOC_RE = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?\s*\n(.*?)\n\s*\1", re.S)
PLACEHOLDER_RE = re.compile(r"@@HEREDOC(\d+)@@")
GH_PR_RE = re.compile(CMD_START + r"gh\s+pr\s+(?:create|edit|merge)(?:\s|$)")
BODY_FILE_RE = re.compile(r"(?:--body-file|-F)\s+(\"[^\"]+\"|'[^']+'|\S+)")
# 바꾸는 경우만 본다: -c core.hooksPath=값, config core.hooksPath 값, --unset · --replace-all 등. 조회는 통과.
# hooksPath는 Git LFS · commit-msg 훅이 있는 기존 폴더를 그대로 쓴다. 게이트는 그 폴더에 심으로 설치한다.
GATE_VALUE = ""
HOOKS_PATH_CHANGE_RE = re.compile(
    r"core\.hooksPath[\"']?\s*=\s*" + GATE_VALUE + r"|config\b[^;&|\n]*?(?:--unset|--replace-all|--add)[^;&|\n]*core\.hooksPath"
    r"|config\b(?:\s+--(?:local|global|system|worktree))*\s+[\"']?core\.hooksPath[\"']?\s+" + GATE_VALUE + r"[^\s;&|]",
    re.I)
# git 별칭 정의(-c alias.x=… · config alias.x 값). 별칭 속 --no-verify는 commit 토큰 검사로 보이지 않는다. 조회는 통과.
ALIAS_DEF_RE = re.compile(
    r"(?:^|\s)-c\s+[\"']?alias\.|config\b(?:\s+--(?:local|global|system|worktree|add|replace-all))*\s+[\"']?alias\.[^\s\"']+[\"']?\s+[^\s;&|]",
    re.I)
SHELL_STRING_PREV = {"-c", "eval"}  # bash -c '…' · eval '…' 문자열 안의 명령도 본다
NO_VERIFY = "--no-" + "verify"
VALUE_OPTS = {"-m", "--message", "-F", "--file", "-C", "-c", "--reuse-message", "--reedit-message",
              "-t", "--template", "--author", "--date", "--fixup", "--squash", "--cleanup"}
AI_MARK_RE = re.compile(r"Co-Authored-By:\s*Claude|Generated with \[?Claude|noreply@anthropic\.com", re.I)


def check_ai_mark(text, where):
    if AI_MARK_RE.search(text or ""):
        fail(f"{where}에 Co-Authored-By: Claude · Generated with Claude 줄을 넣지 않습니다. 해당 줄을 지우세요.")


def fail(reason):
    sys.stderr.write(f"[git 규칙 위반] {reason}\n규칙: docs/agent/git-workflow.md\n")
    sys.exit(2)


def skips_hooks(command):
    """명령 안의 git commit에 훅 건너뛰기 옵션(긴 이름 또는 묶음 short 옵션 속 -n)이 있는지.
    따옴표 안의 ; 로 잘리지 않게 명령 전체를 토큰으로 나누고, bash -c 등에 넘긴 문자열도 다시 본다."""
    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return NO_VERIFY in command
    in_commit = skip = False
    prev = ""
    for token in tokens:
        before, prev = prev, token
        if skip:  # 값을 받는 옵션 뒤 토큰은 값이다(-m ";" 포함)
            skip = False
            continue
        if token and set(token) <= set(";&|()\n"):
            in_commit = False
            continue
        if before in SHELL_STRING_PREV and "commit" in token and skips_hooks(token):
            return True
        if not in_commit:
            in_commit = token == "commit"
            continue
        if token.startswith("--no-v") and NO_VERIFY.startswith(token):  # git은 긴 옵션 축약을 받는다
            return True
        elif token in VALUE_OPTS:
            skip = True
        elif token.startswith("-") and not token.startswith("--"):
            for flag in token[1:]:
                if flag == "n":
                    return True
                if f"-{flag}" in VALUE_OPTS:  # -am "메시지"처럼 값을 받는 옵션 뒤 글자는 값이다
                    break
    return False


def check_message(subject):
    if subject.startswith(("Merge ", "Revert ")):
        return
    subject = SQUASH_SUFFIX_RE.sub("", subject)   # 스쿼시 머지가 붙인 " (#PR번호)"는 규칙 밖이다
    if not HANGUL_RE.search(subject):
        fail(f"커밋 제목은 한국어로 씁니다. 입력: '{subject}'")
    if len(subject) > 50:
        fail(f"커밋 제목은 50자 이하입니다. 현재 {len(subject)}자: '{subject}'")
    if subject.endswith("."):
        fail(f"커밋 제목은 마침표로 끝내지 않습니다. 입력: '{subject}'")


def check_branch(branch):
    if branch in PROTECTED:
        fail(f"보호 브랜치 '{branch}'에는 직접 커밋 · 푸시하지 않습니다. 작업 브랜치에서 PR로 머지하세요.")
    if not BRANCH_RE.match(branch):
        fail(f"브랜치 이름은 '{{종류}}/{{요약}}'입니다(종류: {BRANCH_KINDS.replace('|', ' · ')}, 예: feature/class-edit-20261120). 현재: '{branch}'")


def strip_heredocs(cmd):
    """heredoc 본문을 자리표시(@@HEREDOC{n}@@)로 바꾸고 본문 목록을 돌려준다."""
    bodies = []

    def keep(match):
        bodies.append(match.group(2))
        return f"<<{match.group(1)}\n@@HEREDOC{len(bodies) - 1}@@\n{match.group(1)}"

    return HEREDOC_RE.sub(keep, cmd), bodies


def segment(skeleton, match):
    """git 명령이 시작된 곳부터 다음 명령 구분자 전까지. $( 가 열려 있으면 끝까지 본다."""
    start = match.end()
    end = SEPARATOR_RE.search(skeleton, start)
    if end is None or "$(" in skeleton[start:end.start()]:
        return skeleton[start:]
    return skeleton[start:end.start()]


def first_line(text):
    lines = [line.strip() for line in (text or "").splitlines() if line.strip()]
    return lines[0] if lines else ""


def has_heredoc(part):
    """따옴표 밖의 << 만 heredoc이다(-m "a << b"는 아니다)."""
    try:
        lexer = shlex.shlex(part, posix=True, punctuation_chars="<>;&|()")
        lexer.whitespace_split = True
        return any(token in ("<<", "<<-") for token in lexer)
    except ValueError:
        return False


def message_file(tokens):
    """git commit의 -F 값: -F 경로 · -F경로 · --file 경로 · --file=경로 · -aF 경로."""
    skip = False
    for i, token in enumerate(tokens):
        nxt = tokens[i + 1] if i + 1 < len(tokens) else None
        if skip:
            skip = False
        elif token in ("-F", "--file"):
            return nxt
        elif token.startswith("--file="):
            return token.split("=", 1)[1]
        elif token in VALUE_OPTS:
            skip = True
        elif token.startswith("-") and not token.startswith("--"):
            for j, flag in enumerate(token[1:]):
                if flag == "F":
                    return token[j + 2:] or nxt
                if f"-{flag}" in VALUE_OPTS:  # -am "메시지": 남은 글자나 다음 토큰은 값이다
                    skip = not token[j + 2:]
                    break
    return None


def commit_subject(skeleton, match, part, bodies):
    """실제로 쓰일 메시지의 첫 줄. heredoc은 메시지 입력일 때만 본다:
    -F - <<EOF(구간이 줄바꿈에서 끊겨 본문은 커밋 뒤 첫 heredoc) · -m "$(cat <<EOF …)"(값 안의 자리표시)."""
    tokens = []
    # 구간은 따옴표를 모르고 ; 등에서 잘리므로(-m 'a; b') 따옴표가 안 닫히면 명령 끝까지 다시 읽는다.
    for text in (part, skeleton[match.end():]):
        try:  # 따옴표 밖 ; & | 는 공백 없이 붙어 있어도 따로 자른다
            lexer = shlex.shlex(text, posix=True, punctuation_chars=";&|")
            lexer.whitespace_split = True
            tokens = list(lexer)
            break
        except ValueError:
            continue
    for i, token in enumerate(tokens):   # $( 때문에 구간이 끝까지 이어져도 이 커밋의 인자만 본다
        if set(token) <= set(";&|"):
            tokens = tokens[:i]
            break
    path = message_file(tokens)
    if path == "-":
        placeholder = PLACEHOLDER_RE.search(skeleton, match.end()) if has_heredoc(part) else None
        return first_line(bodies[int(placeholder.group(1))]) if placeholder else ""
    if path:
        try:
            with open(os.path.expanduser(path), encoding="utf-8") as f:
                return first_line(f.read())   # 파일 내용은 셸이 바꾸지 않으므로 $도 그대로 검사한다
        except OSError:
            return ""
    for i, token in enumerate(tokens):
        value = None
        if token in ("-m", "--message") and i + 1 < len(tokens):
            value = tokens[i + 1]
        elif token.startswith("--message="):
            value = token.split("=", 1)[1]
        if value is not None:
            placeholder = PLACEHOLDER_RE.search(value)
            if placeholder:
                return first_line(bodies[int(placeholder.group(1))])
            first = value.splitlines()[0] if value else ""
            raw = MESSAGE_OPT_RE.search(skeleton, match.end())   # 따옴표가 남은 원문으로 셸 확장 여부를 본다
            # 셸 변수 · 명령 치환 제목은 실행 전에 알 수 없다 → 막는다
            return None if raw and expands_first_line(skeleton[raw.end():]) else first
    return ""


MESSAGE_OPT_RE = re.compile(r"(?:^|\s)(?:-m|--message)(?:=|\s+)")
EXPANSION_START = set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789{(@*#?$!-")


def expands_first_line(word):
    """셸 단어 원문의 첫 줄에 실행 때 바뀌는 $이름 · ${ · $( · ` 가 있는지.
    작은따옴표 안 · \\$ · 뒤에 이름이 없는 $('가격 $ 표시')는 글자 그대로다."""
    quote = None
    i = 0
    while i < len(word):
        ch = word[i]
        if ch == "\n":
            return False
        if quote == "'":
            if ch == "'":
                quote = None
        elif ch == "\\":
            i += 1                                   # 다음 글자는 글자 그대로
        elif ch == "`" or (ch == "$" and i + 1 < len(word) and word[i + 1] in EXPANSION_START):
            return True
        elif ch == '"':
            quote = None if quote == '"' else '"'
        elif ch == "'" and quote is None:
            quote = "'"
        elif quote is None and ch in " \t;&|":
            return False                             # 단어 끝
        i += 1
    return False


def git(*args):
    try:
        return subprocess.run(["git", *args], capture_output=True, text=True, timeout=3).stdout.strip()
    except (OSError, subprocess.TimeoutExpired):
        return ""


def current_branch():
    """.git/HEAD를 직접 읽는다(프로세스 생성 없음). worktree · 하위 폴더처럼 .git 폴더가 없을 때만 git을 부른다."""
    if os.path.isdir(".git"):
        try:
            with open(".git/HEAD", encoding="utf-8") as head:
                ref = head.read().strip()
            return ref[len("ref: refs/heads/"):] if ref.startswith("ref: refs/heads/") else "HEAD"
        except OSError:
            pass
    return git("rev-parse", "--abbrev-ref", "HEAD")


CD_RE = re.compile(r"(?:^|&&|;|\n)\s*cd\s+(\"[^\"]+\"|'[^']+'|\S+)")
GIT_C_RE = re.compile(r"git\s+-C\s+(\"[^\"]+\"|'[^']+'|\S+)")


def command_dir(skeleton, first_git, base):
    """git 명령이 실제로 도는 폴더: 그 앞의 마지막 `cd 경로` 또는 `git -C 경로`. 없으면 훅 입력의 cwd."""
    def resolve(path):
        path = os.path.expanduser(path.strip("\"'"))
        return path if os.path.isabs(path) else os.path.join(base, path)

    target = base
    for m in CD_RE.finditer(skeleton[:first_git.start()]):
        target = resolve(m.group(1))
    git_c = GIT_C_RE.search(skeleton, first_git.start(), first_git.end())
    if git_c:
        target = resolve(git_c.group(1))
    return target if os.path.isdir(target) else base


def main():
    if len(sys.argv) == 3 and sys.argv[1] == "--check-message":
        check_message(sys.argv[2]); print("OK"); return
    if len(sys.argv) == 3 and sys.argv[1] == "--check-branch":
        check_branch(sys.argv[2]); print("OK"); return

    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    cmd = data.get("tool_input", {}).get("command", "")

    skeleton, bodies = strip_heredocs(cmd)
    if skips_hooks(cmd):
        fail("pre-commit 검증 게이트를 건너뛰는 옵션(-n 등)은 쓰지 않습니다. verify를 통과시킨 뒤 커밋하세요.")
    if HOOKS_PATH_CHANGE_RE.search(skeleton):
        fail("core.hooksPath를 바꾸면 pre-commit 검증 게이트가 꺼집니다. 바꾸지 않습니다.")
    if ALIAS_DEF_RE.search(skeleton):
        fail("git 별칭(alias)은 정의하지 않습니다. 별칭에 게이트 우회 옵션을 숨길 수 있어 명령을 직접 씁니다.")
    marked = [segment(skeleton, m) for m in list(GH_PR_RE.finditer(skeleton)) + list(COMMIT_RE.finditer(skeleton))]
    if marked:  # 따옴표 안 여러 줄 -m · heredoc 본문까지 보려고 명령 전체를 검사한다
        check_ai_mark(cmd, "커밋 메시지 · PR 본문")
    for part in marked:
        for m in BODY_FILE_RE.finditer(part):
            path = os.path.expanduser(m.group(1).strip("\"'"))
            try:
                with open(path, encoding="utf-8") as f:
                    check_ai_mark(f.read(), "PR 본문 파일")
            except OSError:
                pass  # 아직 없는 파일이면 gh가 직접 오류를 낸다
    commit_matches = list(COMMIT_RE.finditer(skeleton))
    push_matches = list(PUSH_RE.finditer(skeleton))
    commits = [segment(skeleton, m) for m in commit_matches]
    pushes = [segment(skeleton, m) for m in push_matches]
    if not (commits or pushes):
        return

    base = data.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or "."
    first_git = min(commit_matches + push_matches, key=lambda m: m.start())
    os.chdir(command_dir(skeleton, first_git, base))
    branch = current_branch()
    if branch and branch != "HEAD":
        check_branch(branch)

    if any(PUSH_DELETE_RE.search(part) for part in pushes):
        fail("main · develop · release 브랜치는 삭제하지 않습니다.")
    if any(PUSH_PROTECTED_RE.search(part) for part in pushes):
        fail("보호 브랜치(main · develop · release)로 직접 푸시하지 않습니다. PR을 사용하세요.")
    if not commits:
        return

    staged = git("diff", "--cached", "--name-only").splitlines()
    if any(path == ".DS_Store" or path.endswith("/.DS_Store") for path in staged):
        fail(".DS_Store가 스테이징돼 있습니다. 'git rm --cached <경로>'로 빼세요.")
    for m, part in zip(commit_matches, commits):
        subject = commit_subject(skeleton, m, part, bodies)
        if subject is None:
            fail("셸 변수로 만든 -m 메시지는 실행 전에 검사할 수 없습니다. 제목을 -m에 직접 쓰거나 "
                 "-F 파일 · heredoc(-m \"$(cat <<'EOF' …)\")을 쓰세요.")
        if subject:  # -m · -F(heredoc · 파일) 없이 편집기로 쓰는 커밋은 메시지를 검사하지 않는다(에이전트는 편집기를 못 쓴다)
            check_message(subject)
    check_verified()


def check_verified():
    """검증 게이트: 코드 변경이 있는데 verify 통과 기록과 지문이 다르면 커밋을 막는다."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I 실행이라 직접 넣는다
    import harness_state as hs
    try:
        root = hs.repo_root(".")
    except Exception:
        return  # git 저장소가 아니면 git이 직접 알린다
    try:
        warning = hs.install_git_hooks(root)  # 실제 차단은 커밋 직전 index를 보는 pre-commit 훅이 한다
        files = hs.unverified(root)
    except Exception as error:  # 게이트를 설치하거나 판정할 수 없으면 막는다
        fail(f"검증 게이트를 확인하지 못해 커밋을 막습니다({type(error).__name__}: {error}). "
             ".claude/scripts/verify를 실행해 원인을 확인하세요.")
    if warning:
        fail(warning)
    if files:
        shown = ", ".join(files[:5]) + (f" 외 {len(files) - 5}개" if len(files) > 5 else "")
        fail(f"검증하지 않은 코드 변경이 있습니다({shown}). "
             ".claude/scripts/verify로 통과를 확인한 뒤 커밋하세요. 통과 후 코드를 고쳤으면 다시 실행합니다.")


if __name__ == "__main__":
    main()
