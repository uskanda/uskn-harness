#!/usr/bin/env bash
# bash-guard.sh: PreToolUse hook (Bash). Denies the typical ways of changing another repository from the shell and
# warns, via additionalContext, about writes to paths outside the project roots (CLAUDE_PROJECT_DIR and the git top
# level of cwd: project_roots).
#   deny  chezmoi apply|add|update|edit|re-add|merge, unless the session allow file covers the chezmoi source dir
#         a git write subcommand whose repository (-C, --git-dir, --work-tree, GIT_DIR, cd, pushd) is outside
#         a command that names or writes a session allow file (sessions/<id>/allow): only allow-repo.sh writes those
#         a command that names, writes, or removes the verify gate's state (GATE_FILES, a session dir, and for
#         rm | rmdir | mv the sessions dir, the state dir, or above): only the hooks write those
#   warn  redirects and cp|mv|rm|rmdir|ln|tee|mkdir|touch|rsync|install|sed -i whose target is outside the roots
# The command is first split into words and operators (the awk program below): quotes removed, heredoc bodies
# dropped, `$(...)` kept inside its word. Each simple command is then judged on its own, with the working directory
# followed through cd / pushd and restored after a `( ... )` subshell. Words that start with `$` are not guessed.
# Contract (openspec: bash-guard): exit 0 always; silent for commands that stay inside the root; a miss is
# preferred to a false alarm.
set -u
# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
INPUT="$(cat 2>/dev/null || true)"; [ -n "$INPUT" ] || exit 0
CMD="$(json_field "$INPUT" '.tool_input.command' command)"; [ -n "$CMD" ] || exit 0
CWD="$(json_field "$INPUT" '.cwd' cwd)"; SID="$(json_field "$INPUT" '.session_id' session_id)"
ROOTS="$(project_roots "${CWD:-$PWD}")"   # CLAUDE_PROJECT_DIR and the git top level of cwd
# expand ~ and $HOME for the path checks only
CMDX="$(printf '%s' "$CMD" | sed "s#\(^\|[[:space:]=\"']\)~/#\1$HOME/#g; s#\\\$HOME/#$HOME/#g; s#\\\${HOME}/#$HOME/#g")"
GIT_WRITES=' push commit reset checkout switch rebase merge cherry-pick apply am '
CHEZMOI_WRITES=' apply add update edit re-add merge '
DENY=""; WARN=""; GIT_DENIED=0; ALLOW_DENIED=0; GATE_DENIED=0; REMOVING=0
add_deny() { DENY="${DENY:+$DENY }$1"; }
add_warn() { case " $WARN " in *" $1 "*) ;; *) WARN="${WARN:+$WARN }$1" ;; esac; }
outside() { ! path_allowed "$1" "$ROOTS" "$SID"; }   # <abs path>
deny_allow_file() {
  [ "$ALLOW_DENIED" = 1 ] && return 0
  ALLOW_DENIED=1
  add_deny "This command names or writes a session allow file ($USKN_STATE/sessions/<id>/allow). Only the allow-repo skill writes it, when the user asks in this session; to read it, run allow-repo.sh --list --session <sid8>."
}
deny_gate_state() {
  [ "$GATE_DENIED" = 1 ] && return 0
  GATE_DENIED=1
  add_deny "This command names, writes, or removes what $GATE_DENY"
}

# ---- 1. split into words (W), operators (O), and redirections (R), one token per line
# shellcheck disable=SC2016  # awk code, not shell
TOKENIZER='
function flushw() { if (inw) { gsub(/[\t\n]/, " ", w); print "W\t" w; w = ""; inw = 0 } }
function emit(t, v) { flushw(); print t "\t" v }
function bq_end(s, i,   n, c) {
  n = length(s)
  while (i <= n) { c = substr(s, i, 1); if (c == "\\") { i += 2; continue } if (c == "`") return i; i++ }
  return n
}
function skip_dq(s, i,   n, c) {
  n = length(s)
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\"") return i + 1
    if (c == "$" && substr(s, i + 1, 1) == "(") { i = subst_end(s, i + 2) + 1; continue }
    if (c == "`") { i = bq_end(s, i + 1) + 1; continue }
    i++
  }
  return n + 1
}
function subst_end(s, i,   n, c, depth, j) {
  n = length(s); depth = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { i += 2; continue }
    if (c == "\047") { j = index(substr(s, i + 1), "\047"); if (j == 0) return n; i += j + 1; continue }
    if (c == "\"") { i = skip_dq(s, i + 1); continue }
    if (c == "`") { i = bq_end(s, i + 1) + 1; continue }
    if (c == "(") depth++
    else if (c == ")") { depth--; if (depth == 0) return i }
    i++
  }
  return n
}
BEGIN { nq = 0; qh = 1; started = 0; buf = "" }
{
  line = $0
  if (nq >= qh) {                         # a heredoc body: drop it, up to and including its delimiter line
    t = line; if (strip[qh]) sub(/^\t+/, "", t)
    if (t == delim[qh]) qh++
    next
  }
  buf = buf (started ? "\n" : "") line; started = 1
  rest = line
  while (match(rest, /<<-?[ \t]*[\047"]?[A-Za-z_][A-Za-z0-9_]*/)) {
    pre = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : ""
    op = substr(rest, RSTART, RLENGTH); rest = substr(rest, RSTART + RLENGTH)
    if (pre == "<") continue              # <<< is a here-string, not a heredoc
    d = substr(op, 3); s = 0
    if (substr(d, 1, 1) == "-") { s = 1; d = substr(d, 2) }
    gsub(/[ \t\047"]/, "", d)
    nq++; delim[nq] = d; strip[nq] = s
  }
}
END {
  s = buf; n = length(s); i = 1; w = ""; inw = 0
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") { if (substr(s, i + 1, 1) != "\n") { w = w substr(s, i + 1, 1); inw = 1 } i += 2; continue }
    if (c == "\047") {
      j = index(substr(s, i + 1), "\047"); if (j == 0) j = n - i + 1
      w = w substr(s, i + 1, j - 1); inw = 1; i += j + 1; continue
    }
    if (c == "\"") {
      j = skip_dq(s, i + 1); v = substr(s, i + 1, j - i - 2)
      gsub(/\\"/, "\"", v); gsub(/\\\$/, "$", v)
      w = w v; inw = 1; i = j; continue
    }
    if (c == "$" && substr(s, i + 1, 1) == "(") { j = subst_end(s, i + 2); w = w substr(s, i, j - i + 1); inw = 1; i = j + 1; continue }
    if (c == "`") { j = bq_end(s, i + 1); w = w substr(s, i, j - i + 1); inw = 1; i = j + 1; continue }
    if (c == " " || c == "\t") { flushw(); i++; continue }
    if (c == "\n") { emit("O", ";"); i++; continue }
    if (c == "#" && !inw) { while (i <= n && substr(s, i, 1) != "\n") i++; continue }
    if (c == ";") { emit("O", ";"); i++; if (substr(s, i, 1) == ";") i++; continue }
    if (c == "&") {
      d = substr(s, i + 1, 1)
      if (d == "&") { emit("O", "&&"); i += 2; continue }
      if (d == ">") { r = "&>"; i += 2; if (substr(s, i, 1) == ">") { r = "&>>"; i++ } emit("R", r); continue }
      emit("O", "&"); i++; continue
    }
    if (c == "|") {
      d = substr(s, i + 1, 1)
      if (d == "|") { emit("O", "||"); i += 2 } else { emit("O", "|"); i += (d == "&") ? 2 : 1 }
      continue
    }
    if (c == "(" || c == ")") { emit("O", c); i++; continue }
    if (c == ">" || c == "<") {
      if (inw && w ~ /^[0-9]+$/) { w = ""; inw = 0 }   # 2> : the descriptor number is not a word
      flushw()
      r = c; i++; d = substr(s, i, 1)
      if (c == ">" && (d == ">" || d == "|")) { r = r d; i++ }
      else if (c == "<" && d == "<") {
        r = "<<"; i++; d = substr(s, i, 1)
        if (d == "<") { r = "<<<"; i++ } else if (d == "-") { r = "<<-"; i++ }
      }
      else if (c == "<" && d == ">") { r = "<>"; i++ }
      if (substr(s, i, 1) == "&") { r = r "&"; i++ }
      emit("R", r); continue
    }
    w = w c; inw = 1; i++
  }
  flushw()
}'

# ---- 2. judge each simple command
DIR="$(realpath_m "${CWD:-$PWD}")"
DIRS=()        # saved working directories, one per open `(`
WORDS=()
resolve() { # <word> [base]: the absolute path the word names, or failure when it cannot be known without running it
  case "$1" in '' | \$* | \`* | *\$\(*) return 1 ;; /*) realpath_m "$1" ;; *) realpath_m "${2:-$DIR}/$1" ;; esac
}
write_target() { # <word>: a path this command writes
  local p
  p="$(resolve "$1")" || return 0
  if is_allow_file "$p"; then deny_allow_file; return 0; fi
  # the gate's state: a state file, a session dir as the target (cp f <dir>/), or a removal of what holds them all
  if is_gate_file "$p" || is_session_dir "$p" || { [ "$REMOVING" = 1 ] && holds_state "$p"; }; then deny_gate_state; return 0; fi
  outside "$p" && add_warn "$p"
  return 0
}
redirect_target() { # <operator> <word>
  case "$1" in
    '<' | '<<' | '<<-' | '<<<' | '<&') return 0 ;;
    *'&') case "$2" in - | [0-9] | [0-9][0-9]) return 0 ;; esac ;;   # >&2 duplicates a descriptor
  esac
  write_target "$2"
}
positional() { # <first index>: print the arguments that are not options, one per line (`--` ends the options)
  local i="$1" n=${#WORDS[@]} w end=0
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    if [ "$end" = 0 ]; then case "$w" in --) end=1 ;; -?*) ;; *) printf '%s\n' "$w" ;; esac
    else printf '%s\n' "$w"; fi
    i=$((i + 1))
  done
}
do_cd() { # <first index>
  local i="$1" n=${#WORDS[@]} w target="" d
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    case "$w" in -) return 0 ;; -?*) ;; *) target="$w"; break ;; esac   # cd - : unknown, stay
    i=$((i + 1))
  done
  [ -n "$target" ] || target="$HOME"
  d="$(resolve "$target")" && DIR="$d"
  return 0
}
do_git() { # <first index> <GIT_DIR> <GIT_WORK_TREE>
  local i="$1" n=${#WORDS[@]} w repo="$DIR" gd="$2" wt="$3" sub="" target
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    case "$w" in
      -C) i=$((i + 1)); target="$(resolve "${WORDS[$i]:-}" "$repo")" && repo="$target" ;;
      -c | --namespace | --config-env | --super-prefix | --attr-source) i=$((i + 1)) ;;
      --git-dir) i=$((i + 1)); gd="${WORDS[$i]:-}" ;;
      --git-dir=*) gd="${w#--git-dir=}" ;;
      --work-tree) i=$((i + 1)); wt="${WORDS[$i]:-}" ;;
      --work-tree=*) wt="${w#--work-tree=}" ;;
      -*) ;;
      *) sub="$w"; break ;;
    esac
    i=$((i + 1))
  done
  case "$GIT_WRITES" in *" $sub "*) ;; *) return 0 ;; esac
  target="$repo"
  if [ -n "$wt" ]; then target="$(resolve "$wt" "$repo")" || return 0; fi
  if [ -n "$gd" ]; then target="$(resolve "$gd" "$repo")" || return 0; fi
  if outside "$target"; then GIT_DENIED=1; add_deny "git $sub in another repository ($target)."; fi
  return 0
}
CHEZMOI_SRC=""
chezmoi_source() { # <explicit --source or empty>: sets CHEZMOI_SRC
  local src="$1"
  if [ -n "$src" ]; then CHEZMOI_SRC="$(resolve "$src")" || CHEZMOI_SRC="$src"; return 0; fi
  CHEZMOI_SRC=""
  if have chezmoi; then CHEZMOI_SRC="$(with_timeout 5 chezmoi source-path </dev/null 2>/dev/null | head -n 1)" || CHEZMOI_SRC=""; fi
  [ -n "$CHEZMOI_SRC" ] || CHEZMOI_SRC="$HOME/.local/share/chezmoi"
}
chezmoi_allowed() { # the session allow file covers CHEZMOI_SRC (the root and the fixed allowlist do not count)
  local f="$USKN_STATE/sessions/$SID/allow" real a
  [ -n "$SID" ] && [ -s "$f" ] || return 1
  real="$(realpath_m "$CHEZMOI_SRC")"
  while IFS= read -r a; do [ -n "$a" ] && under "$real" "$(realpath_m "$a")" && return 0; done < "$f"
  return 1
}
do_chezmoi() { # <first index>
  local i="$1" n=${#WORDS[@]} w src="" sub=""
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    case "$w" in
      -S | --source) i=$((i + 1)); src="${WORDS[$i]:-}" ;;
      --source=*) src="${w#--source=}" ;;
      -D | --destination | -c | --config | --config-format | --cache | --color | --mode | -o | --output | \
        --persistent-state | -W | --working-tree | --override-data | --override-data-file) i=$((i + 1)) ;;
      -*) ;;
      *) sub="$w"; break ;;
    esac
    i=$((i + 1))
  done
  case "$CHEZMOI_WRITES" in *" $sub "*) ;; *) return 0 ;; esac
  chezmoi_source "$src"
  chezmoi_allowed && return 0
  add_deny "chezmoi $sub changes the live dotfiles and home; dotfiles are changed through a pull request to the dotfiles repository and applied by the user. If the user explicitly allowed changing the dotfiles in this session, run /allow-repo $CHEZMOI_SRC first (the chezmoi source directory)."
}
do_copy() { # <first index> <cmd>: cp / install take -t DIR; otherwise the last argument is the destination
  local i="$1" n=${#WORDS[@]} w tdir="" last="" count=0
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    case "$2:$w" in
      cp:-t | install:-t | *:--target-directory) i=$((i + 1)); tdir="${WORDS[$i]:-}" ;;
      *:--target-directory=*) tdir="${w#*=}" ;;
      *:-?*) ;;
      *) last="$w"; count=$((count + 1)) ;;
    esac
    i=$((i + 1))
  done
  if [ -n "$tdir" ]; then write_target "$tdir"; elif [ "$count" -ge 2 ]; then write_target "$last"; fi
}
do_ln() { # <first index>: the last argument is where the link goes; with one argument it goes into DIR
  local args=() a
  while IFS= read -r a; do args+=("$a"); done < <(positional "$1")
  case "${#args[@]}" in
    0) ;;
    1) write_target "$(basename "${args[0]}")" ;;
    *) write_target "${args[$((${#args[@]} - 1))]}" ;;
  esac
}
do_all() { # <first index>: every argument is written
  local a
  while IFS= read -r a; do write_target "$a"; done < <(positional "$1")
}
do_sed() { # <first index>: only with -i; the script (first argument unless -e / -f) is not a path
  local i="$1" n=${#WORDS[@]} w k ch inplace=0 script=0 files=() f
  while [ "$i" -lt "$n" ]; do
    w="${WORDS[$i]}"
    case "$w" in
      -e | --expression | -f | --file) script=1; i=$((i + 1)) ;;
      --expression=* | --file=*) script=1 ;;
      --in-place*) inplace=1 ;;
      -l | --line-length) i=$((i + 1)) ;;
      --*) ;;
      -?*) # a cluster of short options: -i takes the rest as a suffix; -e / -f take the rest or the next word
        k=1
        while [ "$k" -lt "${#w}" ]; do
          ch="${w:$k:1}"
          case "$ch" in
            i) inplace=1; break ;;
            e | f) script=1; [ "$k" -eq $((${#w} - 1)) ] && i=$((i + 1)); break ;;
            l) [ "$k" -eq $((${#w} - 1)) ] && i=$((i + 1)); break ;;
          esac
          k=$((k + 1))
        done ;;
      *) files+=("$w") ;;
    esac
    i=$((i + 1))
  done
  [ "$inplace" = 1 ] || return 0
  [ "${#files[@]}" -gt 0 ] || return 0
  [ "$script" = 1 ] || files=("${files[@]:1}")
  [ "${#files[@]}" -gt 0 ] || return 0
  for f in "${files[@]}"; do write_target "$f"; done
}
simple_command() {
  local n=${#WORDS[@]} i=0 w wrap=0 gd="" wt="" cmd
  [ "$n" -gt 0 ] || return 0
  while [ "$i" -lt "$n" ]; do   # assignments, reserved words, and wrappers in front of the command
    w="${WORDS[$i]}"
    case "$w" in
      GIT_DIR=*) gd="${w#GIT_DIR=}" ;;
      GIT_WORK_TREE=*) wt="${w#GIT_WORK_TREE=}" ;;
      [A-Za-z_]*=*) case "${w%%=*}" in *[!A-Za-z0-9_]*) break ;; esac ;;
      '{' | '}' | '!' | if | then | else | elif | fi | do | done | while | until | time) ;;
      command | builtin | exec | nohup | sudo | env | nice) wrap=1 ;;
      -?*) [ "$wrap" = 1 ] || break ;;
      *) break ;;
    esac
    i=$((i + 1))
  done
  [ "$i" -lt "$n" ] || return 0
  cmd="${WORDS[$i]##*/}"; i=$((i + 1))
  case "$cmd" in
    cd | pushd) do_cd "$i" ;;
    git) do_git "$i" "$gd" "$wt" ;;
    chezmoi) do_chezmoi "$i" ;;
    cp | install | rsync) do_copy "$i" "$cmd" ;;
    ln) do_ln "$i" ;;
    mv | rm | rmdir) REMOVING=1; do_all "$i"; REMOVING=0 ;;
    mkdir | touch | tee) do_all "$i" ;;
    sed) do_sed "$i" ;;
  esac
  return 0
}

# A command that names a session allow file is denied outright: python -c, a heredoc script, or cat alike.
allow_file_named() {
  local s esc
  printf '%s' "$CMDX" | grep -qE 'uskn-harness/sessions/[A-Za-z0-9_-]+/allow([^[:alnum:]_.-]|$)' && return 0
  for s in "$USKN_STATE" "$(realpath_m "$USKN_STATE")"; do
    esc="$(printf '%s' "$s" | sed 's#[][\.*^$+?(){}|]#\\&#g')"
    printf '%s' "$CMDX" | grep -qE "${esc}/sessions/[A-Za-z0-9_-]+/allow([^[:alnum:]_.-]|\$)" && return 0
  done
  return 1
}
allow_file_named && deny_allow_file
# The same for the verify gate's state files (GATE_FILES): baseline-head or verify.log are not among them.
gate_file_named() {
  local s esc names
  names="$(printf '%s' "$GATE_FILES" | tr ' ' '|')"
  printf '%s' "$CMDX" | grep -qE "uskn-harness/sessions/[A-Za-z0-9_-]+/($names)([^[:alnum:]_.-]|\$)" && return 0
  for s in "$USKN_STATE" "$(realpath_m "$USKN_STATE")"; do
    esc="$(printf '%s' "$s" | sed 's#[][\.*^$+?(){}|]#\\&#g')"
    printf '%s' "$CMDX" | grep -qE "${esc}/sessions/[A-Za-z0-9_-]+/($names)([^[:alnum:]_.-]|\$)" && return 0
  done
  return 1
}
gate_file_named && deny_gate_state

PENDING=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  t="${line%%$'\t'*}"; v="${line#*$'\t'}"
  case "$t" in
    W) if [ -n "$PENDING" ]; then redirect_target "$PENDING" "$v"; PENDING=""; else WORDS+=("$v"); fi ;;
    R) PENDING="$v" ;;
    O)
      PENDING=""; simple_command; WORDS=()
      case "$v" in
        '(') DIRS+=("$DIR") ;;
        ')') if [ "${#DIRS[@]}" -gt 0 ]; then DIR="${DIRS[$((${#DIRS[@]} - 1))]}"; unset "DIRS[$((${#DIRS[@]} - 1))]"; fi ;;
      esac ;;
  esac
done < <(printf '%s\n' "$CMDX" | LC_ALL=C awk "$TOKENIZER" 2>/dev/null || true)
simple_command

if [ -n "$DENY" ]; then
  MSG="uskn-harness: $DENY"
  [ "$GIT_DENIED" = 1 ] && MSG="$MSG Other repositories are changed through a pull request from a fresh clone in the scratchpad, or a handoff document. If the user explicitly allowed it in this session, run /allow-repo <path> first."
  deny_json "$MSG Project roots: $(roots_text "$ROOTS")."
  exit 0
fi
if [ -n "$WARN" ]; then
  MSG="uskn-harness: this command touches paths outside the project roots ($(roots_text "$ROOTS")): $WARN. Other repositories are changed through a PR or a handoff document; if the user explicitly allowed writing there in this session, run /allow-repo <path>."
  if have jq; then jq -c -n --arg m "$MSG" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$m}}'
  else printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$(printf '%s' "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')"; fi
fi
exit 0
