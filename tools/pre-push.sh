#!/usr/bin/env bash
# Pre-push for fsoc.
# Short tests and flint always run.
# The long core suites run only when the push touches that core.
# Full suite is still `fmix test` (no FSOC_SKIP_LONG). fcov is not part of
# this hook: it starts the whole suite again.
#
#   tools/pre-push.sh --list   # read paths on stdin, print test files
# Git passes <local-ref> <local-sha> <remote-ref> <remote-sha> on stdin.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
# shellcheck source=long-core-select.sh
source "$root/tools/long-core-select.sh"

collect_push_files() {
    local local_ref local_sha remote_ref remote_sha
    local z40=0000000000000000000000000000000000000000
    local base
    while read -r local_ref local_sha remote_ref remote_sha; do
        [ "$local_sha" = "$z40" ] && continue
        if [ "$remote_sha" = "$z40" ]; then
            base=$(git merge-base origin/main "$local_sha" 2>/dev/null || true)
            if [ -n "$base" ]; then
                git diff --name-only "$base" "$local_sha"
            else
                git diff-tree --no-commit-id --name-only -r "$local_sha"
            fi
        else
            git diff --name-only "$remote_sha" "$local_sha"
        fi
    done
}

if [ "${1:-}" = "--list" ]; then
    long_core_list_from_stdin
    exit 0
fi

mapfile -t changed < <(collect_push_files)
for path in "${changed[@]}"; do
    consider "$path"
done

long_core_run_gate pre-push
