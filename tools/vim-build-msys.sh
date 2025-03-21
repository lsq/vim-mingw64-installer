#!/bin/env bash
set -x
echo "MSYSTEM: $MSYSTEM"

realpath=$(realpath "$0")
basedir="${realpath%/*}"
vim_msys="https://github.com/msys2/MSYS2-packages/tree/master/vim"
npm install @dking/dgit -g
dgit d $vim_msys -d $basedir/vim-msys
cd $basedir/vim-msys || exit 1
# find "$basedir/vim/src/" -name "cpInfo.ps1" -exec cp -rf {} . \;
[ -z "$vimTag" ] && newerVer="$vimLatestVer"
if [ -n "$newerVer" ]; then
    topver=$(sed -n 's/v\([0-9]\+\.[0-9]\+\)\.\([0-9]\+\)/\1/p' <<<"$newerVer")
    patchlevel=$(sed -n 's/v\([0-9]\+\.[0-9]\+\)\.\([0-9]\+\)/\2/p' <<<"$newerVer")
    sed -i "/^\(_topver=\).*/{s/^\(_topver=\).*/\1$topver/;}" PKGBUILD
    sed -i "/^\(_patchlevel=\).*/{s/^\(_patchlevel=\).*/\1$patchlevel/;}" PKGBUILD
fi

cat >cpInfo.ps1 <<-'EOF'
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
install-Module -Name PoshFunctions -AllowClobber
cd runtime\doc
$cd = $(pwd)
echo $cd
$sinfo = $(get-shortcut -path "$cd\pi_netrw.txt.lnk")
echo $sinfo
Copy-Item -path $sinfo.TargetPath -Destination $cd\pi_netrw.txt -Force
Remove-Item -path pi_netrw.txt.lnk -Force
EOF

# sed -i '/\(--with-compiledby=.*$\)/{s/$/ \\\n    --enable-clientserver --enable-lua\necho ${CHOST}\n/};/^sha256sums/{s/^/noextract=(${pkgname}-${pkgver}.tar.gz)\n/};/^prepare/{s#$#\necho $(pwd);	bsdtar -xf "${srcdir}/${pkgname}-${pkgver}.tar.gz" 2>/dev/null || MSYS=winsymlinks:lnk tar zxf "${srcdir}/${pkgname}-${pkgver}.tar.gz";bsdtar -xf "${srcdir}/${pkgname}-${pkgver}.tar.gz"\n#};/^\s\+iconv/{s#^#if file runtime/doc/pi_netrw.txt|grep symbolic; then\ncp "${srcdir}/../cpInfo.ps1" .\npwsh -command ". \x27.\cpInfo.ps1\x27"\nfi\n#}' PKGBUILD
sed -i '/\(--with-compiledby=.*$\)/{s/$/ \necho ${CHOST}\n/};/^sha256sums/{s/^/noextract=(${pkgname}-${pkgver}.tar.gz)\n/};/^prepare/{s#$#\necho $(pwd);	bsdtar -xf "${srcdir}/${pkgname}-${pkgver}.tar.gz" 2>/dev/null || MSYS=winsymlinks:lnk tar zxf "${srcdir}/${pkgname}-${pkgver}.tar.gz";bsdtar -xf "${srcdir}/${pkgname}-${pkgver}.tar.gz"\n#};/^\s\+iconv/{s#^#if file runtime/doc/pi_netrw.txt|grep symbolic; then\ncp "${srcdir}/../cpInfo.ps1" .\npwsh -command ". \x27./cpInfo.ps1\x27"\nfi\nsed -i \x27s/^\\(\\s\\+return (\\*fname.*\\))/\\1 || strchr((char *)fname,\\x27:\\x27))/\x27 src/os_unix.c\n#}' PKGBUILD

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
