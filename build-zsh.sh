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
