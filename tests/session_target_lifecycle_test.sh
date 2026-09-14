#!/usr/bin/env bash
# singularity-session.target is started by the desktop-session launcher and
# stopped by nothing else. graphical-session.target is StopWhenUnneeded=yes, so
# it only goes away once nothing binds it -- and a user manager that outlives
# the session (lingering enabled, or a second concurrent login) keeps ours
# active after the compositor exits, and with it the portal backend and foot
# server underneath. This asserts the launcher's exit path issues the matching
# stop, and that the older pid-file cleanup still runs alongside it.
set -eu

# Re-entrant stub: the launcher runs this same file as singularity-desktop, and
# a non-zero exit drives the supervisor to its crash budget so the script exits.
if [ "${SINGULARITY_TEST_FAKE_DESKTOP:-0}" = "1" ]; then
    exit 1
fi

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/singularity-session-target-test.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/state" "$TEST_DIR/runtime" "$TEST_DIR/bin"
chmod 700 "$TEST_DIR/runtime"

SYSTEMCTL_LOG="$TEST_DIR/systemctl.log"
: > "$SYSTEMCTL_LOG"

cat > "$TEST_DIR/bin/systemctl" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$SYSTEMCTL_LOG"
EOF
# Keep the launcher's environment probing off the machine running the test.
for stub in pkill xdg-user-dirs-update dbus-update-activation-environment; do
    printf '#!/bin/sh\nexit 0\n' > "$TEST_DIR/bin/$stub"
done
printf '#!/bin/sh\nprintf "false\\n"\n' > "$TEST_DIR/bin/gsettings"
chmod +x "$TEST_DIR"/bin/*

export PATH="$TEST_DIR/bin:$PATH"
export XDG_STATE_HOME="$TEST_DIR/state"
export XDG_RUNTIME_DIR="$TEST_DIR/runtime"
export DBUS_SESSION_BUS_ADDRESS="test-bus"
export SINGULARITY_SESSION_BUILD_ID="session-target-test-build"
export SINGULARITY_DESKTOP_BINARY="$0"
export SINGULARITY_TEST_FAKE_DESKTOP=1

# The launcher under test is generated, so point the test at the configured
# copy in the build dir (SINGULARITY_TEST_DESKTOP_SESSION, set in meson.build).
# Outside meson, fall back to the raw .in template.
LAUNCHER="${SINGULARITY_TEST_DESKTOP_SESSION:-$(dirname "$0")/../src/singularity-desktop-session.in}"
# The supervisor kills $PPID once it gives up, so run the launcher under a
# wrapper that absorbs that signal instead of the test process itself.
set +e
bash -c 'trap "" TERM; bash "$1" & child=$!; wait "$child"' _ "$LAUNCHER"
set -e

grep -Fq -- "--user --no-block start singularity-session.target" "$SYSTEMCTL_LOG" || {
    echo "launcher never started singularity-session.target" >&2
    cat "$SYSTEMCTL_LOG" >&2
    exit 1
}
grep -Fq -- "--user --no-block stop singularity-session.target" "$SYSTEMCTL_LOG" || {
    echo "launcher exited without stopping singularity-session.target" >&2
    cat "$SYSTEMCTL_LOG" >&2
    exit 1
}

# Order matters: a stop that raced ahead of the start would leave the target up.
START_LINE=$(grep -Fn -- "start singularity-session.target" "$SYSTEMCTL_LOG" | head -1 | cut -d: -f1)
STOP_LINE=$(grep -Fn -- "stop singularity-session.target" "$SYSTEMCTL_LOG" | head -1 | cut -d: -f1)
[ "$STOP_LINE" -gt "$START_LINE" ] || {
    echo "stop (line $STOP_LINE) did not follow start (line $START_LINE)" >&2
    cat "$SYSTEMCTL_LOG" >&2
    exit 1
}

# The pre-existing pid-file cleanup has to survive being moved into the
# trap function that now also stops the target.
[ ! -e "$XDG_RUNTIME_DIR/singularity-desktop-session.pid" ] || {
    echo "launcher left its pid file behind" >&2
    exit 1
}
