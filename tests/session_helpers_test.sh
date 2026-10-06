#!/usr/bin/env bash
set -eu

if [ "${SINGULARITY_TEST_FAKE_DESKTOP:-0}" = "1" ]; then
    exit 1
fi

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/singularity-session-helpers-test.XXXXXX")
PIDS=()
cleanup() {
    for p in "${PIDS[@]}"; do
        kill "$p" 2>/dev/null || true
        wait "$p" 2>/dev/null || true
    done
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT
mkdir -p "$TEST_DIR/state" "$TEST_DIR/runtime/singularity-session-helpers" "$TEST_DIR/bin"
chmod 700 "$TEST_DIR/runtime"

for stub in systemctl xdg-user-dirs-update dbus-update-activation-environment; do
    printf '#!/bin/sh\nexit 0\n' > "$TEST_DIR/bin/$stub"
done
printf '#!/bin/sh\nprintf "false\\n"\n' > "$TEST_DIR/bin/gsettings"
chmod +x "$TEST_DIR"/bin/*

SLEEP=$(readlink -f "$(command -v sleep)")
"$SLEEP" 300 & RECORDED=$!; PIDS+=("$RECORDED")
"$SLEEP" 300 & DECOY=$!; PIDS+=("$DECOY")
"$SLEEP" 300 & WRONG_EXE=$!; PIDS+=("$WRONG_EXE")
bash -c 'exec sleep 300' & PREVIOUS=$!; PIDS+=("$PREVIOUS")

printf '%s %s\n%s %s\nnot-a-pid %s\n1 %s\n' \
    "$RECORDED" "$SLEEP" "$WRONG_EXE" "/usr/bin/false" "$SLEEP" "$SLEEP" \
    > "$TEST_DIR/runtime/singularity-session-helpers/$PREVIOUS"
echo "$PREVIOUS" > "$TEST_DIR/runtime/singularity-desktop-session.pid"

export PATH="$TEST_DIR/bin:$PATH"
export XDG_STATE_HOME="$TEST_DIR/state"
export XDG_RUNTIME_DIR="$TEST_DIR/runtime"
export DBUS_SESSION_BUS_ADDRESS="test-bus"
export SINGULARITY_SESSION_BUILD_ID="session-helpers-test-build"
export SINGULARITY_DESKTOP_BINARY="$0"
export SINGULARITY_TEST_FAKE_DESKTOP=1

LAUNCHER="${SINGULARITY_TEST_DESKTOP_SESSION:-$(dirname "$0")/../src/singularity-desktop-session.in}"
set +e
bash -c 'trap "" TERM; bash "$1" & child=$!; wait "$child"' _ "$LAUNCHER"
set -e

alive() {
    [ -e "/proc/$1" ] && ! grep -q '^[0-9]* ([^)]*) Z' "/proc/$1/stat"
}

if alive "$RECORDED"; then
    echo "recorded helper of the previous launcher survived" >&2
    exit 1
fi
alive "$DECOY" || { echo "an unrecorded process with the same name was signalled" >&2; exit 1; }
alive "$WRONG_EXE" || { echo "a recorded pid with a different executable was signalled" >&2; exit 1; }
[ ! -e "$TEST_DIR/runtime/singularity-session-helpers/$PREVIOUS" ] || {
    echo "previous launcher record was left behind" >&2
    exit 1
}
[ -z "$(ls -A "$TEST_DIR/runtime/singularity-session-helpers")" ] || {
    echo "launcher left its own helper record behind" >&2
    ls -A "$TEST_DIR/runtime/singularity-session-helpers" >&2
    exit 1
}
