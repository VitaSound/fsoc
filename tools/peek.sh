#!/bin/sh
# Query ./trace.vcd with wavepeek. Run from the project directory
# after fsoc --build with FSOC_EMU_TRACE set.
set -e
if ! command -v wavepeek >/dev/null 2>&1; then
    echo "wavepeek not found in PATH. Install:" >&2
    echo "  curl --proto '=https' --tlsv1.2 -LsSf https://kleverhq.github.io/wavepeek/install.sh | sh" >&2
    exit 1
fi
if [ ! -f ./trace.vcd ]; then
    echo "Missing ./trace.vcd. Rebuild with FSOC_EMU_TRACE=1" >&2
    exit 1
fi
if [ $# -eq 0 ]; then
    echo "usage: peek.sh <wavepeek command> [args...]" >&2
    echo "example: \"\$FSOC_HOME/tools/peek.sh\" info" >&2
    exit 1
fi
has_waves=0
for a in "$@"; do
    if [ "$a" = "--waves" ]; then
        has_waves=1
    fi
done
if [ "$has_waves" -eq 1 ]; then
    exec wavepeek "$@"
fi
exec wavepeek "$@" --waves ./trace.vcd
