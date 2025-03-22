### vim mingw64 installer 
[![Vim Build](https://github.com/lsq/vim-mingw64-installer/actions/workflows/vim-build.yml/badge.svg)](https://github.com/lsq/vim-mingw64-installer/actions/workflows/vim-build.yml)

- gvim_9.x.x_x86_64.zip: windows protable file.
- mingw-w64-ucrt-x86_64-vim*.pkg.tar.xz: msys2/ucrt64 install file.
- **Fixes and Minor Enhancements**
  - Win64: when running in ucrt/msys, set `$VIMRUNTIME` to default vimruntime dir.
  - Win64: when running in shell environment, set `p_shcf` to `-c`.
  - Win64: patch `mch_settmode()` support raw mode enable virtual terminal processing.
  - Win64: patch garbled GETTEXT messages(default: `CP_UTF8`).
  - Win64: build xpm using mingw64 instead of msvc.
  - Win64: build with tcl/racket.
  - win32unix: `jumpto_tag` support windows path(`C:/src/main.c`).

#### Install

for protable:

```bash
unzip gvim_9.x.x_x86_64.zip
```

for ucrt64:

##### Repo Installation

Add the following code snippet to your `/etc/pacman.conf`:

```conf
[lsq]
SigLevel = Optional
Server = https://github.com/lsq/vim-mingw64-installer/releases/latest/download
```

Then, run `sudo pacman -Sy` to update repository.

#### Packages

##### List repo packages

```bash
pacman -Sl lsq
```

##### Install repo packages

```bash
sudo pacman -S lsq/<package-name>
```

e.g.
```bash
sudo pacman -S lsq/vim
```
