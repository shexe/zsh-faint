# zsh-faint

A tiny patch that adds a `faint` (dim / SGR 2) attribute to zsh's
`zle_highlight` and `region_highlight`, plus a script that builds and installs
a patched zsh.

## Why

Stock zsh's `zle_highlight` supports `bold`, `standout`, and `underline`, but
there is no way to render text faint. That makes it impossible to dim *past*
prompt lines / commands while preserving the exact colours emitted by
`starship` and the syntax-highlighting plugins — a common look in modern
terminals (Ghostty, Kitty, etc.).

This patch adds:

- `Src/zsh.h` — `TXTCFAINT` / `TXTNOCFAINT` flag bits.
- `Src/prompt.c` — a `faint` entry in the `highlights[]` table, so
  `zle_highlight=(faint:...)` and `region_highlight=(... faint ...)` parse.
- `Src/Zle/zle_refresh.c` — emits `\033[2m` / `\033[22m` around faint spans
  and tracks the attribute so it is cleared correctly on the next cell change.

## Build

```sh
./build-zsh.sh
```

Defaults to zsh **5.9.2** and installs to `./install/bin/zsh`.

Overrides:

| Variable      | Default             | Meaning                  |
| ------------- | ------------------- | ------------------------ |
| `ZSH_VERSION` | `5.9.2`             | version to download/build |
| `ZSH_PREFIX`  | `./install`         | install prefix           |
| `ZSH_WORK`    | `/tmp/zsh-$version` | build directory          |

Requires `curl`, `gcc` (Xcode command line tools), and `make`.

## Use

Point your shell at the built binary, e.g. in Ghostty config:

```
command = /path/to/zsh-faint/install/bin/zsh
```

Then an async prompt wrapper can dim past lines while keeping the current
line bright, e.g. with `region_highlight=(... faint ...)` and a faint entry in
`zle_highlight`.

## Notes

- zsh 5.9.2 is used deliberately: 5.9 has a SIGCHLD hang bug on current macOS.
- The patch applies with `patch -p0` from a clean source tree.
- Install to a **stable** prefix. zsh records the configure prefix as its
  `module_path`, so a disposable prefix (e.g. under `/tmp`) makes every module
  — `zsh/parameter`, `zsh/zle`, `zsh/datetime`, ... — unresolvable once that
  directory is cleared. `build-zsh.sh` refuses `/tmp` (and `/var/tmp`) prefixes;
  set `ZSH_ALLOW_EPHEMERAL_PREFIX=1` to override.
