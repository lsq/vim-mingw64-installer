#!/bin/env bash
set -x

vim_msys="https://github.com/msys2/MSYS2-packages/tree/master/vim"
npm install @dking/dgit -g
dgit d $vim_msys -d $basedir/vim-msys
realpath=$(realpath "$0")
basedir="${realpath%/*}"
cd $basedir/vim-msys || exit 1

[ -n "$newerVer" ] && sed -i "/^\(pkgver=\).*/{s/^\(pkgver=\).*/\1$newerVer/;}" PKGBUILD

sed -i '/\(--with-compiledby=.*$\)/{s/$/ \\\n    --enable-clientserver --enable-lua \\\necho ${CHOST}\n/}' PKGBUILD
updpkgsums
makepkg -sCLf --noconfirm
ls
zstFiles=(*.pkg.tar.zst)
if [ -e "${zstFiles[0]}" ]; then
    cp -rf *.pkg.tar.zst $basedir/vim/
else
    echo -e '\033[40;31mvim/msys builed failed !!!\033[0m' >&2
    exit 1
fi

echo -e '\033[40;32mvim/msys builed finished !!!\033[0m' >&2
