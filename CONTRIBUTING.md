# Contributing to singularity-session

## Development setup

```bash
git clone https://github.com/singularityos-lab/singularity-session
cd singularity-session
meson setup build
meson install -C build
```

## Code style

- Shell: POSIX-friendly `bash`, 4-space indentation, no trailing whitespace.
- Keep the launchers prefix-relative: never hardcode an install path.

## License

By contributing you agree your code will be released under [GPL-3.0-only](LICENSE).
