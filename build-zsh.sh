#!/bin/sh
# Build a zsh with a `faint` zle_highlight attribute.
#
# Stock zsh's zle_highlight has no "faint"/dim attribute, so an async prompt
# wrapper cannot dim past command text while keeping the plugins' colours.
# This builds zsh 5.9.2 (the first release where command substitution and
# SIGCHLD handling work correctly on current macOS) with a small patch that
# adds a `faint` attribute emitting SGR 2/22.
#
# Output: $PREFIX/bin/zsh (PREFIX defaults to <repo>/install)
#
# Env overrides:
#   ZSH_VERSION  version to build (default 5.9.2)
#   ZSH_PREFIX   install prefix (default <repo>/install)
#   ZSH_WORK     build dir (default /tmp/zsh-$ZSH_VERSION)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
version="${ZSH_VERSION:-5.9.2}"
prefix="${ZSH_PREFIX:-$here/install}"
work="${ZSH_WORK:-/tmp/zsh-$version}"

# Refuse to bake a disposable install prefix into the binary. zsh records the
# configure prefix as its module_path, so installing under /tmp (or another
# directory the OS clears) leaves every module — zsh/parameter, zsh/zle,
# zsh/datetime, ... — unresolvable the moment that directory disappears.
# Override with ZSH_ALLOW_EPHEMERAL_PREFIX=1 if you really mean it.
case "$prefix" in
    /tmp/*|/var/tmp/*|/private/tmp/*|/private/var/tmp/*)
        if [ "${ZSH_ALLOW_EPHEMERAL_PREFIX:-0}" != "1" ]; then
            echo "refusing to install to an ephemeral prefix: $prefix" >&2
            echo "set ZSH_PREFIX to a stable path, or" >&2
            echo "ZSH_ALLOW_EPHEMERAL_PREFIX=1 to override" >&2
            exit 1
        fi
        ;;
esac

command -v curl >/dev/null || { echo "curl required" >&2; exit 1; }
command -v gcc >/dev/null || { echo "gcc (Xcode CLT) required" >&2; exit 1; }

tarball="/tmp/zsh-$version.tar.xz"
if [ ! -s "$tarball" ]; then
    echo "downloading zsh $version"
    curl -fL --retry 3 -o "$tarball" "https://www.zsh.org/pub/zsh-$version.tar.xz"
fi

rm -rf "$work"
mkdir -p "$work"
tar -xf "$tarball" -C "$work" --strip-components=1

cd "$work"
patch -p0 < "$here/faint.patch"

./configure --prefix="$prefix" >/dev/null
make -j"$(sysctl -n hw.ncpu)" >/dev/null
make install >/dev/null

echo "built $prefix/bin/zsh"
"$prefix/bin/zsh" --version
