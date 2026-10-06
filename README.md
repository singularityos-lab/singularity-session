# Singularity Session

> [!IMPORTANT]
> Report bugs and request features in the
> [Singularity Desktop tracker](https://github.com/singularityos-lab/singularity-desktop/issues/new/choose).

Session launchers and compositor configuration for the Singularity Desktop.

This holds the two static, self-locating launchers used by display managers
and `labwc`, the seed `labwc` configuration, and the scripts that register the
session with GDM.

- `singularity-labwc-session` is the entry point a display manager runs. It
  starts `labwc` (optionally wrapped by `gdm-wayland-session`) with the
  desktop session as its startup command.
- `singularity-desktop-session` is started by `labwc` and brings up the shell,
  the polkit agent, and the portal, then keeps the shell alive.

Both derive their prefix (and `lib`/`share`) from their own install location,
so they work from `/opt/local`, `/usr/local`, or `/usr` without modification.
`singularity-desktop-session` gets its `libexecdir` from Meson at configure
time instead, since a packager can point `-Dlibexecdir=` somewhere that isn't
simply `<prefix>/libexec`.

The desktop session records the processes it starts (shell, polkit agent,
`ush-broker`) in `$XDG_RUNTIME_DIR/singularity-session-helpers/<launcher pid>`.
A new launcher stops only the ones recorded by the launcher it replaces, after
checking each pid still runs the recorded executable, and a launcher stops its
own when it exits. Nothing is stopped by process name, so other sessions of
the same user are left alone.

## Build & Install

```sh
meson setup build
meson install -C build
```

## Register the session

```sh
sudo bash scripts/install-session.sh
sudo bash scripts/install-gdm-config.sh
```

## License

GPL-3.0-only - see [LICENSE](LICENSE).

## Use of Generative AI

Maintainers may use generative AI tools as assistants while working on singularity-session. Non-trivial assisted commits disclose the tool, model, and scope of the work.

AI tools may assist with code comments, documentation, repetitive code, and issue triage. Maintainers make project decisions and review every assisted change before it is merged.

Use these trailers for non-trivial assisted commits:

```plain
Assisted-by: <tool>:<model-version>
AI-Scope: <what the tool generated and the prompt or a short prompt summary>
```

Single-line completions, renames, and formatting changes do not need trailers.

Coding agents must also follow [AGENTS.md](AGENTS.md) before changing files,
creating commits, or opening pull requests.
