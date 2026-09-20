#!/bin/bash
# Sandbox test for the git-sync engine embedded in run.sh (Shell egg).
# Fully hermetic: exercises the engine against local file:// repositories, so
# no network access and no credential helpers are ever involved.
set -u
cd "$(dirname "$0")/.." || exit 1

# Never let a host credential helper pop a dialog or hang the suite.
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/true
export GCM_INTERACTIVE=never
export GIT_CONFIG_SYSTEM=/dev/null

SANDBOX=$(mktemp -d)
export SERVER_DIR="${SANDBOX}/server"
mkdir -p "${SERVER_DIR}"
REPO="${SANDBOX}/repo.git"
WT="${SANDBOX}/wt"
PASS=0; FAIL=0
t_pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
t_fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
G="git -c user.email=test@potenfyr.in -c user.name=SyncTest -c commit.gpgsign=false"

# Minimal logging stubs (names the engine relies on; shell-core provides the
# real ones at runtime)
log()  { printf '[log] %s\n' "$*"; }
ok()   { printf '[ok] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
info() { printf '[info] %s\n' "$*"; }
error() { printf '[error] %s\n' "$*" >&2; }
_egg_error_log() { :; }

python3 tests/extract_funcs.py run.sh > "${SANDBOX}/functions.sh" || exit 1
# shellcheck disable=SC1090
source "${SANDBOX}/functions.sh"
# The protected-path list is a top-level assignment (not a function) - pull it.
# shellcheck disable=SC1091
eval "$(sed -n "/^_PF_SYNC_PROTECTED='/,/'\$/p" run.sh)"
[ -n "${_PF_SYNC_PROTECTED:-}" ] || { echo "FATAL: protected list missing"; exit 1; }

commit() { # commit FILE CONTENT MSG
    mkdir -p "${WT}/$(dirname "$1")" 2>/dev/null || true
    printf '%s\n' "$2" > "${WT}/$1"
    ${G} -C "${WT}" add -A >/dev/null
    ${G} -C "${WT}" commit -qm "$3" >/dev/null
    git -C "${WT}" push -q origin HEAD >/dev/null 2>&1
}

echo "== Shell git sync engine tests (hermetic) =="

${G} init -q --bare -b main "${REPO}"
${G} clone -q "${REPO}" "${WT}" 2>/dev/null
commit "tools/my-script.sh" "echo hi" "c1"
commit "dotfiles/bashrc" "alias ll='ls -la'" "c1"

echo "--- T1: no repo configured (must be a silent no-op) ---"
sync_git_repo && t_pass "no-op returns zero" || t_fail "no-op failed"

echo "--- T2: first sync via file:// URL (local repo) ---"
GIT_REPO_URL="file://${REPO}"
sync_git_repo || t_fail "sync returned nonzero"
[ -f "${SERVER_DIR}/tools/my-script.sh" ] && t_pass "script synced" || t_fail "script missing"
[ -f "${SERVER_DIR}/dotfiles/bashrc" ] && t_pass "dotfile synced" || t_fail "dotfile missing"
[ -s "${SERVER_DIR}/.git-sync/manifest" ] && t_pass "manifest written" || t_fail "manifest missing"

echo "--- T3: second run with no new commit (up to date) ---"
out=$(sync_git_repo 2>&1)
printf '%s' "${out}" | grep -qi "up to date" && t_pass "reports up to date" || t_fail "no up-to-date message"

echo "--- T4: protected paths never touched by repo content ---"
mkdir -p "${SERVER_DIR}/logs" "${SERVER_DIR}/payloads"
echo "keep" > "${SERVER_DIR}/logs/boot.log"
echo "state" > "${SERVER_DIR}/payloads/payload.state"
commit "logs/evil.log" "evil" "try write into logs/"
sync_git_repo || t_fail "sync failed with protected content"
grep -q keep "${SERVER_DIR}/logs/boot.log" && t_pass "logs/ preserved" || t_fail "logs/ overwritten"
[ ! -f "${SERVER_DIR}/logs/evil.log" ] && t_pass "repo content into logs/ blocked" || t_fail "repo wrote into logs/"
grep -q state "${SERVER_DIR}/payloads/payload.state" && t_pass "payloads/ preserved" || t_fail "payloads/ overwritten"

echo "--- T5: new upstream commit picked up, deletion propagates ---"
${G} -C "${WT}" rm -q dotfiles/bashrc >/dev/null 2>&1
commit "tools/my-script.sh" "echo hi2" "c2"
sync_git_repo || t_fail "update sync failed"
grep -q "hi2" "${SERVER_DIR}/tools/my-script.sh" && t_pass "update applied" || t_fail "stuck on old commit"
[ ! -e "${SERVER_DIR}/dotfiles/bashrc" ] && t_pass "upstream deletion propagated" || t_fail "deleted file still present"

echo "--- T6: unreachable repo keeps files, returns non-zero ---"
GIT_REPO_URL="https://127.0.0.1:1/nope.git"
sync_git_repo >/dev/null 2>&1 && t_fail "unreachable repo reported success" || t_pass "failure signalled (non-zero)"
grep -q "hi2" "${SERVER_DIR}/tools/my-script.sh" && t_pass "files kept" || t_fail "files lost"

echo "--- T7: token'd sync works against a repo that ignores tokens ---"
commit "tools/my-script.sh" "echo hi3" "c3"
GIT_REPO_URL="file://${REPO}"
GIT_TOKEN="ghp_faketoken123456"
sync_git_repo || t_fail "token'd sync failed"
grep -q "hi3" "${SERVER_DIR}/tools/my-script.sh" && t_pass "sync works with token set" || t_fail "token'd sync stuck"
unset GIT_TOKEN

echo "--- T8: branch switch ---"
${G} -C "${WT}" checkout -qb test
commit "tools/branch-only.sh" "echo branch" "branch c1"
${G} -C "${WT}" checkout -q main
GIT_REPO_URL="file://${REPO}"
GIT_BRANCH="test"
sync_git_repo || t_fail "branch switch failed"
[ -f "${SERVER_DIR}/tools/branch-only.sh" ] && t_pass "branch content synced" || t_fail "branch switch failed"

echo "--- T9: GIT_PRESERVE_ENV keeps live .env credentials across updates ---"
GIT_BRANCH=""
mkdir -p "${SERVER_DIR}/tools/app"
printf 'SHELL_ENV_SECRET=live-secret\n' > "${SERVER_DIR}/.env"
printf 'TOOL_KEY=live-tool-secret\n' > "${SERVER_DIR}/tools/app/.env"
commit ".env" "SHELL_ENV_SECRET=repo-override" "c4 repo env"
commit "tools/app/.env" "TOOL_KEY=repo-tool-override" "c4 tool env"
sync_git_repo || t_fail ".env update sync failed"
grep -q "live-secret" "${SERVER_DIR}/.env" && t_pass "root .env preserved (old credentials win)" || t_fail "root .env clobbered"
grep -q "live-tool-secret" "${SERVER_DIR}/tools/app/.env" && t_pass "sub-path .env restored in its original location" || t_fail "sub-path .env clobbered"

echo "--- T10: GIT_PRESERVE_ENV=0 lets the repository's .env win ---"
GIT_PRESERVE_ENV=0
commit "tools/app/.env" "TOOL_KEY=repo-tool-new" "c5 repo env update"
sync_git_repo || t_fail "opt-out sync failed"
grep -q "repo-tool-new" "${SERVER_DIR}/tools/app/.env" && t_pass "repo .env wins when opted out" || t_fail "repo .env not applied"
unset GIT_PRESERVE_ENV

echo "--- T11: GIT_EXCLUDE keeps user paths out of the sync ---"
GIT_EXCLUDE="tools/keep"
commit "tools/keep/user.txt" "should-not-land" "c6 excluded"
commit "tools/app/run.py" "v2-content" "c6 tracked update"
sync_git_repo || t_fail "exclusion sync failed"
grep -q "should-not-land" "${SERVER_DIR}/tools/keep/user.txt" && t_fail "GIT_EXCLUDE ignored" || t_pass "excluded path never installed"
grep -q "v2-content" "${SERVER_DIR}/tools/app/run.py" && t_pass "non-excluded paths still sync" || t_fail "exclusion broke normal sync"
unset GIT_EXCLUDE

rm -rf "${SANDBOX}"
echo
echo "Results: $PASS passed, $FAIL failed"
[ "${FAIL}" -eq 0 ]
