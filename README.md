# Singularity Session

Session launchers and compositor configuration for the Singularity Desktop.

This holds the two static, self-locating launchers used by display managers
and `labwc`, the seed `labwc` configuration, and the scripts that register the
session with GDM.

- `singularity-labwc-session` is the entry point a display manager runs. It
  starts `labwc` (optionally wrapped by `gdm-wayland-session`) with the
  desktop session as its startup command.
- `singularity-desktop-session` is started by `labwc` and brings up the shell,
  the polkit agent, and the portal, then keeps the shell alive.

Both derive their prefix from their own location, so they work from
`/opt/local`, `/usr/local`, or `/usr` without modification.

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
