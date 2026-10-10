#!/usr/bin/env bash
# Pre-commit for fsoc.
# Short tests and flint always run.
# The long core suites run only when the staged index touches that core.
# Full suite is still `fmix test` (no FSOC_SKIP_LONG).
#
#   tools/pre-commit.sh --list   # read paths on stdin, print test files

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
# shellcheck source=long-core-select.sh
source "$root/tools/long-core-select.sh"

collect_staged_files() {
    git diff --cached --name-only --diff-filter=ACMRD
}

if [ "${1:-}" = "--list" ]; then
    long_core_list_from_stdin
    exit 0
fi

mapfile -t changed < <(collect_staged_files)
for path in "${changed[@]}"; do
    consider "$path"
done

long_core_run_gate pre-commit
