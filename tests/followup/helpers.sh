#!/usr/bin/env bash
# Shared fixtures and assertions for the followup tests. Source it; do not
# run it. Every test runs the script under test against a throwaway git repo
# with a faked HOME so the developer's global git config (signing, identity,
# excludes) cannot leak into the run.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FOLLOWUP="$REPO_ROOT/skills/finishing-a-development-branch/scripts/followup"

FAILURES=0
TEST_ROOT="$(mktemp -d)"
# Physical spelling, so paths compare equal to what git prints (macOS /var
# vs /private/var).
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
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

# make_repo NAME -> path of a fresh repo on branch main with one commit and
# no ignore rule
make_repo() {
  local repo="$TEST_ROOT/$1"
  mkdir -p "$repo"
  g -C "$repo" -c init.defaultBranch=main init -q
  g -C "$repo" config user.name "Test Bot"
  g -C "$repo" config user.email "test@example.com"
  printf 'hello\n' >"$repo/README"
  g -C "$repo" add -A
  g -C "$repo" commit -q -m "chore: init"
  printf '%s\n' "$repo"
}

# fu DIR ARGS... -> run the script under test with -C DIR
fu() {
  local dir=$1
  shift
  HOME="$FAKE_HOME" XDG_CONFIG_HOME="$FAKE_HOME/.config" GIT_CONFIG_NOSYSTEM=1 "$FOLLOWUP" -C "$dir" "$@"
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

# assert_status DESCRIPTION EXPECTED_STATUS CMD... -> CMD exits with that status
assert_status() {
  local description=$1 expected=$2 status=0
  shift 2
  "$@" >/dev/null 2>&1 || status=$?
  assert_eq "$description" "$expected" "$status"
}

# assert_fails DESCRIPTION NEEDLE CMD... -> CMD exits 1, prints nothing on
# stdout and exactly one stderr line containing NEEDLE
assert_fails() {
  local description=$1 needle=$2 out err status=0 lines
  shift 2
  err="$TEST_ROOT/stderr"
  out=$("$@" 2>"$err") || status=$?
  lines=$(wc -l <"$err" | tr -d ' ')
  if [ "$status" -ne 1 ]; then
    fail "$description"
    echo "    expected exit status 1, got $status"
  elif [ -n "$out" ] || [ "$lines" -ne 1 ]; then
    fail "$description"
    echo "    expected only a one-line reason on stderr, got stdout:"
    printf '%s\n' "$out" | sed 's/^/      /'
    echo "    stderr:"
    sed 's/^/      /' "$err"
  elif grep -Fq -- "$needle" "$err"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected the reason to contain: $needle"
    sed 's/^/      /' "$err"
  fi
}

finish() {
  if [ "$FAILURES" -gt 0 ]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
  fi
  echo "STATUS: PASSED"
}
