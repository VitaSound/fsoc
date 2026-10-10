# Shared long-core test selection for pre-commit / pre-push.
# Source from those scripts; do not exec this file alone.
#
#   tools/pre-push.sh --list   # stdin paths → selected test files
#   tools/pre-commit.sh --list

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
        fsys/common/*|fsys/host/cross.4th)
            note tests/con_core_test.4th
            note tests/common_test.4th
            note tests/j1abs_test.4th
            ;;
        emu/*)
            note tests/con_core_test.4th
            note tests/common_test.4th
            note tests/j1abs_test.4th
            note tests/bcpu_test.4th
            note tests/cd16_test.4th
            note tests/msl16_test.4th
            note tests/z80_test.4th
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
        cpu/cd16/*|fsys/kernel/cd16/*|fsys/cd16/*|\
        fsys/fasm/cd16/*|fsys/host/cd16-cross.4th|\
        firmware/cd16_blink.fs|firmware/blink_cd16.4th)
            note tests/con_core_test.4th
            note tests/cd16_test.4th
            ;;
        tests/cd16_test.4th)
            note tests/cd16_test.4th
            ;;
        cpu/msl16/*|fsys/kernel/msl16/*|fsys/msl16/*|\
        fsys/fasm/msl16/*|fsys/host/msl16-cross.4th|\
        firmware/msl16_blink.fs|firmware/blink_msl16.4th)
            note tests/con_core_test.4th
            note tests/msl16_test.4th
            ;;
        tests/msl16_test.4th)
            note tests/msl16_test.4th
            ;;
        cpu/z80/*|fsys/kernel/z80/*|fsys/z80/*|\
        fsys/fasm/z80/*|fsys/host/z80-cross.4th|\
        firmware/z80_blink.fs|firmware/blink_z80.4th)
            note tests/con_core_test.4th
            note tests/z80_test.4th
            ;;
        tests/z80_test.4th)
            note tests/z80_test.4th
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
        cpu/mcpu/dual_pingpong.v|firmware/mcpu_ping.4th|\
        firmware/mcpu_pong.4th|fsoc/tasks/dual-mcpu.4th|\
        fsoc/tasks/dual_mcpu_main.cpp|projects/baremetal/dual_mcpu_emul/*)
            note tests/dual_mcpu_pingpong_test.4th
            ;;
        tests/dual_mcpu_pingpong_test.4th)
            note tests/dual_mcpu_pingpong_test.4th
            ;;
    esac
}

# Read paths from stdin, print sorted selected test files (or nothing).
long_core_list_from_stdin() {
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        consider "$path"
    done
    if [ "${#want[@]}" -eq 0 ]; then
        return 0
    fi
    printf '%s\n' "${!want[@]}" | sort
}

# Jobs for xargs -P: FSOC_TEST_JOBS, else nproc, capped at 8.
long_core_jobs() {
    local j=${FSOC_TEST_JOBS:-}
    if [ -z "$j" ]; then
        j=$(nproc 2>/dev/null || echo 4)
    fi
    if [ "$j" -gt 8 ]; then
        j=8
    fi
    if [ "$j" -lt 1 ]; then
        j=1
    fi
    printf '%s\n' "$j"
}

# stdin: one test path per line. Buffered logs; non-zero if any fail.
long_core_run_parallel() {
    local label=$1
    local jobs
    jobs=$(long_core_jobs)
    echo "* ${label}: parallel jobs=${jobs}"
    xargs -r -P "$jobs" -I{} bash -c '
        log=$(mktemp)
        if fmix test "$1" >"$log" 2>&1; then
            cat "$log"
            rm -f "$log"
            exit 0
        else
            cat "$log"
            rm -f "$log"
            exit 1
        fi
    ' _ {}
}

# Short suite + flint + selected long files. $1 is a label for log lines.
long_core_run_gate() {
    local label=$1

    echo "* ${label}: short suite"
    export FSOC_SKIP_LONG=1
    printf '%s\n' tests/*_test.4th | sort | long_core_run_parallel "${label}-short"
    unset FSOC_SKIP_LONG

    : "${FLINT_HOME:=$HOME/flint}"
    "$FLINT_HOME/bin/flint" lint . --strict --project-only

    if [ "${#want[@]}" -eq 0 ]; then
        echo "* ${label}: no long core tests for this change"
        return 0
    fi

    echo "* ${label} long tests:"
    printf '  %s\n' $(printf '%s\n' "${!want[@]}" | sort)
    printf '%s\n' "${!want[@]}" | sort | long_core_run_parallel "${label}-long"
}
