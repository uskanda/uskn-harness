#!/usr/bin/env bats
# The tests and the scripts must behave the same on Linux and on macOS, where bats and the hooks run under /bin/bash
# 3.2 with BSD tools. Three traps make a check pass there while checking nothing:
#   - bash before 4.1 ignores a failing [[ ]] in the middle of a test (set -e does not apply to it);
#   - BSD find has no printf action, so a before/after listing is empty both times and always equal;
#   - BSD sed and grep have no \| \+ \? in a basic regex, so the expression silently matches nothing.

REPO="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

# tracked <pathspec...>: absolute paths of the tracked files that match
tracked() { git -C "$REPO" ls-files -- "$@" | sed "s#^#$REPO/#"; }

@test "every [[ ]] statement in a bats file ends with || false, so its failure counts under bash 3.2" {
  # A [[ ]] that starts a statement and ends it (next comes ;, }, a comment, or the end of the line). One inside an
  # if, or already followed by || or &&, is not a statement of its own.
  run perl -ne '
    next if /^\s*#/;
    while (/(?:^|;|\bdo|\bthen|\belse|\{|&&)\s*(\[\[ .*? \]\])(?=\s*(?:;|\}|#|$))/g) { print "$ARGV:$.: $1\n" }
    close ARGV if eof' $(tracked '*.bats')
  [ "$status" -eq 0 ]
  [ -z "$output" ] || { printf '%s\n' "$output" | head -n 20; false; }
}

@test "no bats file lists a tree with find's printf action (BSD find lacks it); listing does the same in perl" {
  run perl -ne 'next if /^\s*#/; print "$ARGV:$.: $_" if /\bfind\b.*\s-printf\b/; close ARGV if eof' $(tracked '*.bats')
  [ "$status" -eq 0 ]
  [ -z "$output" ] || { printf '%s\n' "$output"; false; }
}

@test "the installer and the hook scripts use no GNU-only option or basic-regex extension" {
  # sed or grep without -E (or -r / -P) whose expression holds \| \+ \?; sed -i with no suffix argument; stat -c; date -d
  run perl -ne '
    next if /^\s*#/;
    print "$ARGV:$.: $_" if /\bsed\b(?![^|;]*\s-[a-zA-Z]*[Er])[^|;]*\\[|+?]/
      || /\bgrep\b(?![^|;]*\s-[a-zA-Z]*[EP])[^|;]*\\[|+?]/
      || /\bsed\s+-i\s+[\x27"s]/ || /\bstat\s+-c\b/ || /\bdate\s+-d\b/;
    close ARGV if eof' "$REPO/bin/uskn-harness" $(tracked 'plugins/uskn-harness/hooks/scripts/*.sh' 'plugins/uskn-harness/hooks/scripts/lib/*.sh' 'plugins/uskn-harness/bin/*')
  [ "$status" -eq 0 ]
  [ -z "$output" ] || { printf '%s\n' "$output"; false; }
}

@test "the basic-regex check catches the tilde expansion bash-guard once had, and passes its -E form" {
  run perl -ne 'print if /\bsed\b(?![^|;]*\s-[a-zA-Z]*[Er])[^|;]*\\[|+?]/' <<'EOF'
CMDX="$(printf '%s' "$CMD" | sed "s#\(^\|[[:space:]=\"']\)~/#\1$HOME/#g; s#\\\$HOME/#$HOME/#g")"
EOF
  [ -n "$output" ]
  run perl -ne 'print if /\bsed\b(?![^|;]*\s-[a-zA-Z]*[Er])[^|;]*\\[|+?]/' <<'EOF'
CMDX="$(printf '%s' "$CMD" | sed -E "s#(^|[[:space:]=\"'])~/#\1$HOME/#g; s#\\\$HOME/#$HOME/#g")"
EOF
  [ -z "$output" ]
}
