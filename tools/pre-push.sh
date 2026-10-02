#!/usr/bin/env bash
# Pre-push for fsoc.
# Short tests and flint always run.
# The long core suites run only when the push touches that core.
# `fmix test` still runs every file. fcov is not part of this hook:
# it starts the whole suite again.
#
#   tools/pre-push.sh --list   # read paths on stdin, print test files
# Git passes <local-ref> <local-sha> <remote-ref> <remote-sha> on stdin.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

declare -A want=()

note() {
    want["$1"]=1
}

# j1a and j1b consoles, plus the j1abs port of the j1a image.
consider() {
    local f=$1
    case "$f" in
        tests/fixture.4th|tests/test_common.4th)
            note tests/con_core_test.4th
            note tests/common_test.4th
            note tests/j1abs_test.4th
            note tests/bcpu_test.4th
            note tests/avr_con_test.4th
            note tests/avr_dict_test.4th
            note tests/avr_words_test.4th
            note tests/avr_pin_test.4th
            note tests/avr_soc_blink_test.4th
            ;;
        tests/con_session.4th|tests/con_words.py|doc/j1-word-graph/*)
            note tests/con_core_test.4th
            note tests/j1abs_test.4th
            note tests/avr_con_test.4th
            ;;
        cpu/j1/j1a/*|cpu/j1/j1b/*|cpu/j1/uart.v|\
        fsys/kernel/j1a/*|fsys/kernel/j1b/*|\
        fsys/j1a/*|fsys/j1b/*|\
        fsys/fasm/j1a/*|fsys/fasm/j1b/*|\
        fsys/common/*|fsys/host/cross.4th|\
        swapforth/*)
            note tests/con_core_test.4th
            note tests/common_test.4th
            note tests/j1abs_test.4th
            ;;
        emu/*)
            note tests/con_core_test.4th
            note tests/common_test.4th
            note tests/j1abs_test.4th
            note tests/bcpu_test.4th
            ;;
        tests/con_core_test.4th)
            note tests/con_core_test.4th
            ;;
        tests/common_test.4th)
            note tests/common_test.4th
            ;;
        cpu/j1/j1abs/*|firmware/blink_j1abs.4th|tests/j1abs_test.4th)
            note tests/j1abs_test.4th
            ;;
        cpu/bcpu/*|fsys/kernel/bcpu/*|fsys/bcpu/*|\
        fsys/fasm/bcpu/*|fsys/host/bcpu-cross.4th|\
        firmware/bcpu_blink.fs|firmware/blink_bcpu.4th)
            note tests/con_core_test.4th
            note tests/bcpu_test.4th
            ;;
        tests/bcpu_test.4th)
            note tests/bcpu_test.4th
            ;;
        fsys/kernel/avr/*|fsys/avr/*|fsys/fasm/avr/*|\
        fsys/host/avr-cross.4th|\
        firmware/blink.fs|firmware/blink_avr.4th|tools/avr-con*)
            note tests/con_core_test.4th
            note tests/avr_con_test.4th
            note tests/avr_dict_test.4th
            note tests/avr_words_test.4th
            note tests/avr_pin_test.4th
            note tests/avr_soc_blink_test.4th
            ;;
        tests/avr_con_test.4th)
            note tests/avr_con_test.4th
            ;;
        tests/avr_dict_test.4th)
            note tests/avr_dict_test.4th
            ;;
        tests/avr_words_test.4th)
            note tests/avr_words_test.4th
            ;;
        tests/avr_pin_test.4th)
            note tests/avr_pin_test.4th
            ;;
        tests/avr_soc_blink_test.4th)
            note tests/avr_soc_blink_test.4th
            ;;
    esac
}

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
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        consider "$path"
    done
    if [ "${#want[@]}" -eq 0 ]; then
        exit 0
    fi
    printf '%s\n' "${!want[@]}" | sort
    exit 0
fi

mapfile -t changed < <(collect_push_files)
for path in "${changed[@]}"; do
    consider "$path"
done

export FSOC_SKIP_LONG=1
fmix test
unset FSOC_SKIP_LONG

: "${FLINT_HOME:=$HOME/flint}"
"$FLINT_HOME/bin/flint" lint . --strict --project-only

if [ "${#want[@]}" -eq 0 ]; then
    echo "* pre-push: no long core tests for this push"
    exit 0
fi

echo "* pre-push long tests:"
printf '  %s\n' $(printf '%s\n' "${!want[@]}" | sort)
for test in $(printf '%s\n' "${!want[@]}" | sort); do
    fmix test "$test"
done
