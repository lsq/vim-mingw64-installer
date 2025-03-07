### vim mingw64 installer 
[![Vim Build](https://github.com/lsq/vim-mingw64-installer/actions/workflows/vim-build.yml/badge.svg)](https://github.com/lsq/vim-mingw64-installer/actions/workflows/vim-build.yml)

- gvim_9.x.x_x86_64zip
- mingw-w64-ucrt-x86_64-vim*.pkg.tar.xz

#### install
for protable:

```bash
unzip gvim_9.x.x_x86_64zip
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
