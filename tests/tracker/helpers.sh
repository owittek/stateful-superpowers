#!/usr/bin/env bash
# Shared fixtures and assertions for the tracker-port tests. Source it; do not
# run it. Every test runs the script under test inside a throwaway git repo
# with a faked HOME so the developer's global git config (signing, identity)
# cannot leak into the run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TRACKER="$REPO_ROOT/skills/picking-up-ticket/scripts/tracker"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
FAKE_HOME="$TEST_ROOT/home"
mkdir -p "$FAKE_HOME"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

# g GIT_ARGS... -> git with the same clean environment the script under test sees
g() {
  HOME="$FAKE_HOME" XDG_CONFIG_HOME="$FAKE_HOME/.config" GIT_CONFIG_NOSYSTEM=1 git "$@"
}

# make_repo NAME [H1] -> path of a fresh repo whose docs/agents/issue-tracker.md
# carries the given H1 (default: the Local Markdown backend), committed
make_repo() {
  local repo="$TEST_ROOT/$1" h1="${2:-Issue tracker: Local Markdown}"
  mkdir -p "$repo/docs/agents"
  g -C "$repo" -c init.defaultBranch=main init -q
  g -C "$repo" config user.name "Test Bot"
  g -C "$repo" config user.email "test@example.com"
  printf '# %s\n\nTracker config for the tests.\n' "$h1" >"$repo/docs/agents/issue-tracker.md"
  g -C "$repo" add -A
  g -C "$repo" commit -q -m "chore: tracker config"
  printf '%s\n' "$repo"
}

# tracker REPO OP [ARGS...] -> run the script under test from inside REPO
tracker() {
  local repo=$1
  shift
  (cd "$repo" && HOME="$FAKE_HOME" XDG_CONFIG_HOME="$FAKE_HOME/.config" GIT_CONFIG_NOSYSTEM=1 "$TRACKER" "$@")
}

# assert_eq DESCRIPTION EXPECTED ACTUAL
assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1"
  else
    fail "$1"
    echo "    expected: $2"
    echo "    actual:   $3"
  fi
}

# assert_line DESCRIPTION LINE TEXT -> TEXT contains LINE as a whole line
assert_line() {
  if printf '%s\n' "$3" | grep -Fqx -- "$2"; then
    pass "$1"
  else
    fail "$1"
    echo "    expected line: $2"
    echo "    in:"
    printf '%s\n' "$3" | sed 's/^/      /'
  fi
}

# assert_no_line DESCRIPTION LINE TEXT
assert_no_line() {
  if printf '%s\n' "$3" | grep -Fqx -- "$2"; then
    fail "$1"
    echo "    did not expect line: $2"
  else
    pass "$1"
  fi
}

# assert_file_exists DESCRIPTION FILE
assert_file_exists() {
  if [ -f "$2" ]; then
    pass "$1"
  else
    fail "$1"
    echo "    missing: $2"
  fi
}

# assert_file_has_line DESCRIPTION FILE LINE
assert_file_has_line() {
  if grep -Fqx -- "$3" "$2" 2>/dev/null; then
    pass "$1"
  else
    fail "$1"
    echo "    expected line: $3"
    echo "    in: $2"
    sed 's/^/      /' "$2" 2>/dev/null || echo "      (file missing)"
  fi
}

# assert_fails DESCRIPTION NEEDLE CMD... -> CMD exits 1 and prints exactly
# one line (stdout+stderr) containing NEEDLE
assert_fails() {
  local description=$1 needle=$2 out status=0 lines
  shift 2
  out=$("$@" 2>&1) || status=$?
  lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  if [ "$status" -ne 1 ]; then
    fail "$description"
    echo "    expected exit status 1, got $status"
  elif [ "$lines" -ne 1 ]; then
    fail "$description"
    echo "    expected a one-line reason, got $lines lines:"
    printf '%s\n' "$out" | sed 's/^/      /'
  elif printf '%s' "$out" | grep -Fq -- "$needle"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected the reason to contain: $needle"
    printf '%s\n' "$out" | sed 's/^/      /'
  fi
}

finish() {
  if [ "$FAILURES" -gt 0 ]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
  fi
  echo "STATUS: PASSED"
}
