#!/usr/bin/env bash
# terms-check.sh: the sensor for the terminology guard (openspec: terminology-guard). Two checks over prose:
#   names   every `backticked` name must exist as a path, a path element, or text in a tracked file
#   terms   every katakana word and 「quoted」 term must be in openspec/glossary.yml or the common-word list
#
#   terms-check.sh <file.md> ...        CLI: print findings, exit 1 when there are any (make verify)
#   (stdin JSON)                        PostToolUse hook: findings as additionalContext, never blocks
#
# Contract: exit 0 in hook mode whatever happens; silent when there is nothing to report; skipped entirely
# when USKN_SKIP_TERMS=1. Code fences, code spans, links and English documents are out of scope.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"

[ "${USKN_SKIP_TERMS:-0}" = 1 ] && exit 0

MODE=cli
FILES=()
if [ $# -gt 0 ]; then FILES=("$@")
else
  INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
  [ -z "$(json_field "$INPUT" '.agent_type' agent_type)" ] || exit 0
  MODE=hook
  F="$(json_field "$INPUT" '.tool_input.file_path' file_path)"; [ -n "$F" ] || exit 0
  CWD="$(json_field "$INPUT" '.cwd' cwd)"
  case "$F" in /*) ;; *) F="${CWD:-$PWD}/$F" ;; esac
  FILES=("$(realpath_m "$F")")
fi

ROOT="$(project_root "${CWD:-$PWD}")"
GLOSSARY="$ROOT/openspec/glossary.yml"
ALLOW="$ROOT/openspec/known-names.txt"
COMMON="${USKN_COMMON_WORDS:-$(harness_dir)/skills/ja-writing/common-words.txt}"

# The whole check is one awk-free python pass: the text work (fences, spans, katakana runs) is beyond
# what bash and jq do well, and python3 is already a dependency of the harness helpers.
have python3 || exit 0

OUT="$(python3 - "$ROOT" "$GLOSSARY" "$ALLOW" "$COMMON" "${FILES[@]}" <<'PY' 2>/dev/null || true
import os, re, subprocess, sys

root, glossary_path, allow_path, common_path, *files = sys.argv[1:]
if not files:
    sys.exit(0)

def read(p):
    try:
        with open(p, encoding="utf-8") as fh:
            return fh.read()
    except OSError:
        return ""

# ---- what counts as an existing name -------------------------------------------------
def git(*args):
    try:
        return subprocess.run(["git", "-C", root, *args], capture_output=True, text=True,
                              timeout=20).stdout.split()
    except Exception:
        return []

# untracked files count too: a document may name a file added in the same change
tracked = git("ls-files") + git("ls-files", "--others", "--exclude-standard")
paths = set(tracked)
for p in tracked:
    paths.add(os.path.basename(p))
    paths.update(p.split("/"))
corpus = []
for p in tracked:
    if p.endswith((".md", ".markdown")):
        continue
    if "/tests/" in p or p.endswith((".bats", ".test.ts", ".test.js", "_test.py")):
        continue     # a fixture names things that deliberately do not exist
    corpus.append(read(os.path.join(root, p)))
corpus = "\n".join(corpus)
allow = {ln.strip() for ln in read(allow_path).splitlines() if ln.strip() and not ln.startswith("#")}

# ---- glossary and common words -------------------------------------------------------
canonical, alias_of = set(), {}
gl = read(glossary_path)
if gl:
    term = None
    for line in gl.splitlines():
        m = re.match(r'\s*-\s+term:\s*"?([^"\n]+)"?\s*$', line)
        if m:
            term = m.group(1).strip()
            canonical.add(term)
            continue
        m = re.match(r'\s*aliases:\s*\[(.*)\]\s*$', line)
        if m and term:
            for a in re.findall(r'"([^"]+)"', m.group(1)):
                alias_of[a] = term
common = {ln.strip() for ln in read(common_path).splitlines() if ln.strip() and not ln.startswith("#")}
known_terms = canonical | common | set(alias_of)

def prose(text):
    text = re.sub(r"^```.*?^```", "", text, flags=re.S | re.M)   # fenced code
    text = re.sub(r"^(?:    |\t).*$", "", text, flags=re.M)      # indented code
    return text

NAME_SPAN = re.compile(r"`([^`\n]+)`")
KATAKANA = re.compile(r"[ァ-ヶー]{3,}")
QUOTED = re.compile(r"「([^」\n]{2,20})」")

TOP = {p.split("/")[0] for p in tracked}

def is_name_like(tok):
    """A name this repository is responsible for. Anything that names another system is out of scope:
    the check cannot tell a real foreign name from an invented one, and guessing would drown the signal."""
    if re.search(r"[^\x00-\x7F]", tok):      # holds non-ASCII: it is prose, not a name
        return False
    if len(tok) < 2 or len(tok) > 60:
        return False
    if any(c in tok for c in " =<>…*@$"):     # prose, placeholders, globs, addresses, shell variables
        return False
    if tok.startswith(("-", "/")) or tok.endswith(":"):   # flags and slash commands
        return False
    if re.fullmatch(r"v(?:\d{2}|YY)\.(?:\d{2}|MM)\.[\dX]+", tok):   # version examples
        return False
    if "/" in tok:                            # a path: ours only when it starts at a top-level entry
        return tok.lstrip("~/").split("/")[0] in TOP
    if re.fullmatch(r"[\d.]+", tok):          # section and version numbers
        return False
    return "." in tok.lstrip(".")             # a bare word is not a name; a filename is

def name_exists(tok):
    if tok in allow or tok in paths or tok in canonical:
        return True
    bare = tok.strip("~/.")
    if bare in paths or bare.split("/")[0] in paths:
        return True
    # a file or directory that exists in the working tree counts even when git does not track it yet
    for cand in (tok, bare):
        if cand and not cand.startswith("/") and os.path.exists(os.path.join(root, cand)):
            return True
    if tok in corpus or bare in corpus:
        return True
    return False

def japanese(text):
    kana = len(re.findall(r"[぀-ゟ゠-ヿ]", text))
    return len(text) > 0 and kana * 100 // max(len(text), 1) >= 3

findings = []
for f in files:
    raw = read(f)
    if not raw:
        continue
    body = prose(raw)
    rel = os.path.relpath(f, root)
    for tok in dict.fromkeys(NAME_SPAN.findall(body)):
        if is_name_like(tok) and not name_exists(tok):
            findings.append(f"{rel}: 実在しない名前 `{tok}`。"
                            f"実物の名前に直すか、仮名なら <> で囲むか、openspec/known-names.txt に足す")
    if not japanese(body):
        continue
    if not gl:
        continue
    text = re.sub(r"`[^`\n]*`", "", body)
    text = re.sub(r"\[([^\]]*)\]\([^)\s]*\)", r"\1", text)
    # aliases that hold kanji never appear as a katakana run, so look for them directly
    for a, canon in alias_of.items():
        if re.fullmatch(r"[ァ-ヶー]+", a):
            continue
        if a in text:
            findings.append(f"{rel}: 用語集は「{canon}」。「{a}」は避ける別名")
    for w in dict.fromkeys(KATAKANA.findall(text)) :
        if w in alias_of:
            findings.append(f"{rel}: 用語集は「{alias_of[w]}」。「{w}」は避ける別名")
        elif w not in known_terms:
            findings.append(f"{rel}: 用語集にも一般語リストにも無い語「{w}」。"
                            f"用語集に定義を足すか、既存の語に言い換える")
    for w in dict.fromkeys(QUOTED.findall(text)):
        if re.search(r"[ぁ-ゟ]", w) or len(w) < 4:   # ordinary Japanese phrases, not terms
            continue
        if not re.search(r"[^\x00-\x7F]", w):      # an English phrase in quotes is not a Japanese term
            continue
        if any(c in w for c in " /、。"):            # a phrase or a list, not a term
            continue
        if w in paths or w in allow:                # a file or a name that is already known
            continue
        if w in alias_of:
            findings.append(f"{rel}: 用語集は「{alias_of[w]}」。「{w}」は避ける別名")
        elif w not in known_terms:
            findings.append(f"{rel}: 用語集に無い語「{w}」。用語集に定義を足すか、既存の語に言い換える")

for line in dict.fromkeys(findings):
    print(line)
PY
)"

[ -n "$OUT" ] || exit 0
N="$(printf '%s\n' "$OUT" | grep -c .)"

if [ "$MODE" = cli ]; then printf '%s\n' "$OUT" >&2; exit 1; fi

MAX=20
CAP=""; [ "$N" -gt "$MAX" ] && CAP=" (showing the first $MAX)"
MSG="uskn-harness terms: $N problem(s)$CAP. Names must exist; terms must be in openspec/glossary.yml. The rules are in the ja-writing skill.
$(printf '%s\n' "$OUT" | head -n "$MAX")"
if have jq; then jq -c -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$m}}'
else printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')"; fi
exit 0
