set -x
basedir=$(realpath "${0%/*}")
echo "$MSYSTEM"
pacman --noconfirm --sync --needed pactoys
pacman-key --recv-keys BE8BF1C5
pacman-key --lsign-key BE8BF1C5
repman add ci.ri2 "https://github.com/oneclick/rubyinstaller2-packages/releases/download/ci.ri2"
pacman -Syuu --noconfirm
#pacman -Sy --needed --noconfirm "ruby$rubyversion"
pacboy sync --needed --noconfirm ed:
pacboy sync --needed --noconfirm lua:p
pacboy sync --needed --noconfirm jq:p
pacboy sync --needed --noconfirm libsodium:p
pacboy sync --needed --noconfirm ci.ri2::ruby32:p
#cd ./vim
#MINGW_ARCH=msys makepkg-mingw --cleanbuild --syncdeps --force --noconfirm
#cd $APPVEYOR_BUILD_FOLDER/tools/vim
cd "${basedir}"/vim || exit
#export LUA_PREFIX=/ucrt64
#export rubyhome=/c/Ruby-on-Windows/3.2.5-1
echo "$PATH"
#PATH=/${MSYSTEM}/bin:/${MSYSTEM}/bin/site_perl/5.38.2:/${MSYSTEM}/bin/vendor_perl:/${MSYSTEM}/bin/core_perl:/usr/local/bin:/usr/bin:/bin
#export PATH=$rubyhome/bin:$PATH
#ridk.cmd install
#echo $PATH
ls "$rubyhome"/bin/
rbpat=$(which ruby)
rbdir=${rbpat%/*}
rubyhm=${rbdir%/*}
rubyversion=$(ruby -v | sed -r -n 's/.* (([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2} .*/\2\3/p')
rubyapiver=$(ruby -v | sed -r -n 's/.* (([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2} .*/\10/p')
#sed -i "s|RUBY=\${ruby_home}|RUBY=${rubyhm}|" PKGBUILD
#sed -i "s|RUBY_VER=32|RUBY_VER=${rubyversion}|" PKGBUILD
#sed -i "s|RUBY_API_VER_LONG=3.2.0|RUBY_API_VER_LONG=${rubyapiver}|" PKGBUILD
sed -n 's/\r//p' PKGBUILD
export rubyversion rubyapiver rubyhm

pythonver=$(sed 's/\x0d\x0a//' <<< $(powershell '$webc=(iwr https://www.python.org/downloads/windows).content; $mstatus = $webc -match "Latest Python \d Release - Python (?<version>[\d.]+)"; $Matches["version"]'))
#pypat=$(which python3)
#pydir=${rbpat%/*}
#pyhm=${rbdir%/*}
pymajor=$(echo "${pythonver}" | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\2/p')
pyminor=$(echo "${pythonver}" | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\3/p')
pyversion=$(echo "${pythonver}" | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\2\3/p') # 313
pyapiver=$(echo "${pythonver}" | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2}))\.[0-9]{1,2}.*/\1/p') # 3.13
if pacboy find "python${pyapiver}:p"; then
	pacboy find "python${pyapiver}:p"
else 
	pyversion=$((pyversion -1))
	pyapiver=${pymajor}.$((pyminor - 1))
	pacboy find "python${pyapiver}:p" || { echo "python $pyapiver not find" && exit 1; }
fi
export pyversion pyapiver
#sed -n 's/\r//p' PKGBUILD

luaversion=$(lua -v | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\2\3/p')
tclshversionlong=$(tclsh - <<< 'puts $tcl_patchLevel')
tclversion=$(echo ${tclshversionlong} | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\2\3/p')
tclapiver=$(echo ${tclshversionlong} | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2}))\.[0-9]{1,2}.*/\1/p')
perlversion=$(perl -v | sed -r -n 's/.*(([0-9]{1,2})\.([0-9]{1,2})\.)[0-9]{1,2}.*/\2\3/p')
export luaversion perlversion tclversion tclapiver

racketBin=$(which racket)
if [[ ${racketBin} =~ "shim" ]] ;then
    racketB=$(cat ${racketBin}.shim)
    racketBHome=${racketB##*\ }
fi
racketbin=${racketBHome//\"/}
racketHome=$(cygpath -u ${racketbin%\\*})
echo ${racketHome}
racketlib=${racketHome}/lib
echo ${racketlib}
mzlib=$(ls ${racketlib}/libracket*.dll)
mzVer=$(sed 's|libracket||;s|\.dll||' <<< $(basename "$mzlib"))
echo $mzVer
export racketHome
export mzVer

pkgver() {
  local ver
  ver=$(curl https://api.github.com/repos/vim/vim/tags | jq -r '.[0].name'|sed 's/v//') 
  if [[ -z $ver ]]; then
	prjInfo=$(curl https://release-monitoring.org/project/5092)
	#echo $prjInfo
	ver=$(echo ${prjInfo} | sed -n '/>Latest version<\/h/{:t N;s|.*>Latest version<\/h.*doap:Version\">\([^<]*\) (.*</div>.*|\1|p;T t;q}')
  fi
  if [[ -n $GITHUB_ACTIONS && -n $vimTag ]]; then
        ver=$vimTag
  fi
  printf "${ver}"
  #sed -n 's/\r//p' PKGBUILD
}
olderVer=$(sed -n ':t;n;s/pkgver=\(.*\)/\1/;T t;p;q' PKGBUILD)
newerVer=$(pkgver)
if [ -n "$newerVer" ] && [ $(vercmp "$olderVer" "$newerVer") -ne 0 ]; then
	sed -i "/^\(pkgver=\).*/{s/^\(pkgver=\).*/\1$newerVer/;}" PKGBUILD
	updpkgsums
	#chsm=$(makepkg-mingw -oeg |sed ':t;N;$! bt;s/\n/|/g;s/\x27/#/g;')
	#sed -i '\~^sha256sums=~{:t N;s~.*\x27)~'"$chsm"'~;T t;s~#~\x27~g;s~|~\n~g;}' PKGBUILD
	#printf '%s\n' "g/1/s//$chsm/" 'wq' | ed -s sed.txt
fi
#MINGW_ARCH=ucrt64 makepkg-mingw -eo
MINGW_ARCH=ucrt64 makepkg-mingw -sLf --noconfirm
libsodiumVer=$(pacman -Qi mingw-w64-ucrt-x86_64-libsodium | grep -Po '^(版本|Version)\s*: \K.+')
VIMVER="$newerVer"
VIMVERMAJOR=$(awk -F'.' '{print $1$2}' <<< "$newerVer")
interfaceInfo=$(cat src/vim-"${VIMVER}"/src/if_ver.txt|sed -r -n 's/\s*(.*):\s*$/\* \1:/;3!p')
if [ -z "$APPVEYOR_REPO_NAME" ]; then
   CI_REPO_NAME=$GITHUB_REPOSITORY
    CI_REPO_TAG_NAME="vim${VIMVER}"
    echo "tagName=${CI_REPO_TAG_NAME}" >> $GITHUB_ENV
else
    CI_REPO_NAME=$APPVEYOR_REPO_NAME
    CI_REPO_TAG_NAME=$APPVEYOR_REPO_TAG_NAME
fi
URL="https://github.com/$CI_REPO_NAME/releases/download"
releaseLog="[![${CI_REPO_NAME}](https://img.shields.io/github/downloads/${CI_REPO_NAME}/${CI_REPO_TAG_NAME}/total.svg)](https://github.com/${CI_REPO_NAME}/releases/tag/${CI_REPO_TAG_NAME})
### Files:
#### :unlock: Unsigned Files:
* [![gvim_${VIMVER}_x64.zip](https://img.shields.io/github/downloads/${CI_REPO_NAME}/${CI_REPO_TAG_NAME}/gvim_${VIMVER}_x64.zip.svg?label=downloads&logo=vim)](${URL}/${CI_REPO_TAG_NAME}/gvim_${VIMVER}_x86_64.zip)
        64-bit zip archive
* [![gvim_${VIMVER}_x64.zip](https://img.shields.io/github/downloads/${CI_REPO_NAME}/${CI_REPO_TAG_NAME}/mingw-w64-ucrt-x86_64-vim${VIMVERMAJOR}-${VIMVER}-1-any.pkg.tar.zst.svg?label=downloads&logo=vim)](${URL}/${CI_REPO_TAG_NAME}/mingw-w64-ucrt-x86_64-vim${VIMVERMAJOR}-${VIMVER}-1-any.pkg.tar.zst)
        64-bit ucrt installer archive

<details>
<summary>Interface Information</summary>
${interfaceInfo}
* [libsodium](https://download.libsodium.org/libsodium/) ${libsodiumVer}
</details>
"
#if [[ -n $APPVEYOR_REPO_NAME ]]; then
if [ -n "$APPVEYOR_REPO_NAME" ]; then
    echo "$releaseLog" | sed -e ':a;N;$!ba;s/\n/\\n/g' > "$basedir"/../gitlog.txt
else
    echo "$releaseLog" > "$basedir"/../gitlog.txt
fi
cat "$basedir"/../gitlog.txt
