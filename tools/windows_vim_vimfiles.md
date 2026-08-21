# [DeepWiki Q&A with Code Context for Repository: vim/vim](https://deepwiki.com/search/windowsvimrcvimfiles-runtimepa_cba2dadc-1cd0-4b33-962f-b515c3bbdc63)
## Q1
在windows系统上默认配置文件为_vimrc和vimfiles, runtimepath会加入~/vimfiles，如果使用bash环境，怎么修改使得默认为.vimrc和.vim
### Answer
## 在 Windows 上让 Vim 使用 `.vimrc` / `.vim`（而不是 `_vimrc` / `vimfiles`）

Windows (Win32) 版本的默认路径是在 `src/os_dos.h` 中通过宏硬编码的：

```c
#define USR_VIMRC_FILE   "$HOME\\_vimrc"
#define USR_VIMRC_FILE2  "$HOME\\vimfiles\\vimrc"
#define USR_VIMRC_FILE3  "$VIM\\_vimrc"
#define USR_EXRC_FILE    "$HOME\\_exrc"
#define USR_EXRC_FILE2   "$VIM\\_exrc"
#define VIMRC_FILE       "_vimrc"
#define EXRC_FILE        "_exrc"
#define DFLT_RUNTIMEPATH "$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
``` vim:16-27 vim:73-79 vim:107-109 

启动流程文档（`runtime/doc/starting.txt`）明确说明了 Win32 平台的查找顺序和优先级：

```
Places for your personal initializations:
    MS-Windows	$HOME/_vimrc, $HOME/vimfiles/vimrc
                or $VIM/_vimrc
``` vim:827-831 

同一份文档还提到：Windows 下 Vim 只在 `$HOME` 找不到 `_vimrc` 时，才会去尝试 `.vimrc`，而且是"`_vimrc` 找不到再找 `.vimrc`"（顺序和 Unix 相反）：

```
Note: For Win32, "$HOME" is checked first.  If no "_vimrc" or
".vimrc" is found there, "$VIM" is tried.
``` vim:890-896 

### 结论 / 可行做法

编译好的 vim.exe 里，`.vimrc`/`.vim` 目录名并没有被完全禁用——它只是被排在 `_vimrc`/`vimfiles` 之后作为“备选”，本身逻辑是硬编码在 `os_dos.h` 里的宏，普通用户无法通过运行时配置项去改变检测顺序（除非重新编译 Vim，用不同的宏值）。因此如果你在 Windows + bash（如 Git Bash / MSYS2 / WSL 之类）环境下想让 Vim 表现得跟 Unix 一致（用 `.vimrc` 和 `.vim/`），常见做法是：

1. **直接创建 `.vimrc`**：因为 Win32 分支在 `$HOME` 下找不到 `_vimrc` 时才会退回尝试 `.vimrc`（前提是使用长文件名系统），所以只要不建立 `_vimrc`，只建立 `.vimrc`，Vim 依然可以读取到它。
2. **runtimepath 里的 `vimfiles`**：`DFLT_RUNTIMEPATH` 宏写死为 `$HOME/vimfiles,...`，Windows 版可执行文件不会自动把 `$HOME/.vim` 加入 `runtimepath`。要让 `.vim` 目录生效，可以在 `.vimrc` 最前面手动设置：
   ```vim
   set runtimepath^=~/.vim
   set runtimepath+=~/.vim/after
   let &packpath = &runtimepath
   ```
   这样插件、语法文件等仍会从 `~/.vim` 加载，而不依赖编译期宏。
3. 如果确实需要底层彻底改成 Unix 风格（比如让 `$MYVIMRC`、`exrc` 探测顺序也变成 Unix 风格），那就需要修改 `src/os_dos.h` 中的宏定义并重新编译 Windows 版 Vim（把 `USR_VIMRC_FILE` 等改成 `.vimrc`/`.vim`），这不是运行时可配置的选项。

需要注意：这些宏是编译期常量，运行时无法通过 `:set` 或环境变量修改查找顺序本身（只能通过设置 `$HOME`、`$VIM`、`$MYVIMRC` 等环境变量间接影响“查找到哪个具体文件”，参见 `runtime/doc/os_dos.txt`） vim:23-54 。所以对绝大多数用户而言，方案 1+2（直接用 `.vimrc` 并在其中手动扩展 `runtimepath` 指向 `~/.vim`）是最简单、不需要重新编译的做法。
### Citations
**File:** src/os_dos.h (L16-27)
```text
#ifndef SYS_VIMRC_FILE
# define SYS_VIMRC_FILE		"$VIM\\vimrc"
#endif
#ifndef USR_VIMRC_FILE
# define USR_VIMRC_FILE		"$HOME\\_vimrc"
#endif
#ifndef USR_VIMRC_FILE2
# define USR_VIMRC_FILE2	"$HOME\\vimfiles\\vimrc"
#endif
#ifndef USR_VIMRC_FILE3
# define USR_VIMRC_FILE3	"$VIM\\_vimrc"
#endif
```
**File:** src/os_dos.h (L73-79)
```text
#ifndef VIMRC_FILE
# define VIMRC_FILE	"_vimrc"
#endif

#ifndef EXRC_FILE
# define EXRC_FILE	"_exrc"
#endif
```
**File:** src/os_dos.h (L107-109)
```text
#define DFLT_ERRORFILE		"errors.err"
#define DFLT_RUNTIMEPATH	"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
#define CLEAN_RUNTIMEPATH	"$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
```
**File:** runtime/doc/starting.txt (L827-831)
```text
	Places for your personal initializations:
		Unix		$HOME/.vimrc, $HOME/.vim/vimrc
				or $XDG_CONFIG_HOME/vim/vimrc
		MS-Windows	$HOME/_vimrc, $HOME/vimfiles/vimrc
				or $VIM/_vimrc
```
**File:** runtime/doc/starting.txt (L890-896)
```text
		Note: For Unix and Amiga, when ".vimrc" does not exist,
		"_vimrc" is also tried, in case an MS-DOS compatible file
		system is used.  For MS-Windows ".vimrc" is checked after
		"_vimrc", in case long file names are used.
		Note: For Win32, "$HOME" is checked first.  If no "_vimrc" or
		".vimrc" is found there, "$VIM" is tried.  See |$VIM| for when
		$VIM is not set.
```
**File:** runtime/doc/os_dos.txt (L23-54)
```text
1. File locations					*dos-locations*

If you keep the Vim executable in the directory that contains the help and
syntax subdirectories, there is no need to do anything special for Vim to
work.  No registry entries or environment variables need to be set.  Just make
sure that the directory is in your search path, or use a shortcut on the
desktop.

Your vimrc files ("_vimrc" and "_gvimrc") are normally located one directory
up from the runtime files.  If you want to put them somewhere else, set the
environment variable $VIM to the directory where you keep them.  Example: >
	set VIM=C:\user\piet
Will find "c:\user\piet\_vimrc".
Note: This would only be needed when the computer is used by several people.
Otherwise it's simpler to keep your _vimrc file in the default place.

If you move the executable to another location, you also need to set the $VIM
environment variable.  The runtime files will be found in "$VIM/vim{version}".
Example: >
	set VIM=E:\vim
Will find the version 8.2 runtime files in "e:\vim\vim82".
Note: This is _not_ recommended.  The preferred way is to keep the executable
in the runtime directory.

If you move your executable AND want to put your "_vimrc" and "_gvimrc" files
somewhere else, you must set $VIM to where you vimrc files are, and set
$VIMRUNTIME to the runtime files.  Example: >
	set VIM=C:\usr\piet
	set VIMRUNTIME=E:\vim\vim82
Will find "c:\user\piet\_vimrc" and the runtime files in "e:\vim\vim82".

See |$VIM| and |$VIMRUNTIME| for more information.
```
## Q2
DFLT_RUNTIMEPATH在哪里使用，怎么修改为运行时根据shell是否是unix风格决定
### Answer
## `DFLT_RUNTIMEPATH` 在哪里使用

`DFLT_RUNTIMEPATH` 是一个**编译期宏**，按平台分别在 `src/os_unix.h`、`src/os_dos.h`、`src/os_mac.h`、`src/os_amiga.h`、`src/os_haiku.h` 中定义（Windows 版即 `src/os_dos.h`）：

```c
#define DFLT_RUNTIMEPATH "$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
#define CLEAN_RUNTIMEPATH "$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
``` vim:107-109 

它的使用点主要有三处：

1. **`src/optiondefs.h`**：`'runtimepath'`（`p_rtp`）选项表中，把 `DFLT_RUNTIMEPATH` 作为该选项的编译期默认值（`def_val`），即 Vim 启动时如果用户没有在 vimrc 之前设置过 `runtimepath`，就会用这个宏字符串初始化 `p_rtp`。 vim:276-301 
2. **`src/main.c`**：当使用 `--clean` 参数启动时（跳过用户配置、仅用干净环境），会用 `CLEAN_RUNTIMEPATH` 而不是 `DFLT_RUNTIMEPATH` 来设置 `runtimepath`/`packpath`，从而排除 `$HOME` 下的用户目录。
3. **`src/option.c`**：在选项初始化/重置逻辑（如 `set_init_1()` 一类函数）中引用这个宏字符串来给 `p_rtp` 赋初值，并据此计算 `'packpath'` 的默认值。

需要说明：因为工具索引对大文件有截断限制，我没能拿到 `main.c` 和 `option.c` 里这几处引用的具体代码行，如果需要精确定位这几行代码，建议在 Devin 会话里直接 `grep DFLT_RUNTIMEPATH src/main.c src/option.c` 查看。

## 能否“运行时根据 shell 是否是 unix 风格决定”

这一点在当前架构下**做不到纯运行时判断**，原因是：

- `DFLT_RUNTIMEPATH` / `CLEAN_RUNTIMEPATH` 是 C 预处理器宏，在编译时就被替换成固定字符串写进二进制文件，Vim 运行时不会重新计算这个宏，也没有“检测当前 shell 类型”的逻辑。 vim:107-109 
- Vim 内部并没有“unix 风格 shell 检测”这样的概念；`UNIX`/`MSWIN` 之类是编译时的平台宏（例如 `os_unix.h` vs `os_dos.h` 分别对应 Unix 编译目标和 Win32 编译目标），不是运行时通过环境变量（如 `$SHELL`、`$MSYSTEM`）动态切换的。

如果确实想要“同一个 Win32 二进制，在 bash 环境下自动表现成 Unix 风格 runtimepath”，概念上只有两种路径：

1. **运行时脚本层面绕过**（不改源码）：在 `.vimrc`/`_vimrc` 最前面，通过判断某个环境变量（比如 MSYS2 的 `$MSYSTEM`、Git Bash 的 `$OSTYPE`/`$SHELL`）来动态 `set runtimepath^=...` 覆盖默认值。这是目前唯一不需要重新编译就能达到类似效果的方式，本质上是在 vimrc 里手写"检测 + set runtimepath"逻辑，而不是修改 `DFLT_RUNTIMEPATH` 本身。
2. **修改源码重新编译**：让 `set_init_1()`（`option.c` 里初始化默认选项值的函数）在设置 `p_rtp` 默认值之前，先用 C 代码检测运行环境（例如检查 `getenv("MSYSTEM")` 或 `getenv("SHELL")` 是否存在/匹配 bash 类特征），据此在运行时选择拼接 Unix 风格路径（`$HOME/.vim,...`）还是 Windows 风格路径（`$HOME/vimfiles,...`），而不是直接用预处理宏字符串赋值。这需要改动 C 代码逻辑本身，属于功能新增，不是简单的宏替换。

简单说：`DFLT_RUNTIMEPATH` 目前的设计就是"编译时按平台固定"，如果要做成运行时按 shell 类型动态决定,必须修改 `option.c` 里初始化 `p_rtp` 的那段代码，把"直接赋值宏字符串"改成"运行时判断后再拼接字符串"，这是源码级改动而非配置项。 vim:276-301
### Citations
**File:** src/os_dos.h (L107-109)
```text
#define DFLT_ERRORFILE		"errors.err"
#define DFLT_RUNTIMEPATH	"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
#define CLEAN_RUNTIMEPATH	"$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
```
**File:** src/optiondefs.h (L276-301)
```text
struct vimoption
{
    char	*fullname;	// full option name
    char	*shortname;	// permissible abbreviation
    long_u	flags;		// see in option.h
    char_u	*var;		// global option: pointer to variable;
				// window-local option: VAR_WIN;
				// buffer-local option: global value
    idopt_T	indir;		// global option: PV_NONE;
				// local option: indirect option index
    // callback function to invoke after an option is modified to validate and
    // apply the new value.
    opt_did_set_cb_T	opt_did_set_cb;

    // callback function to invoke when expanding possible values on the
    // cmdline. Only useful for string options.
    opt_expand_cb_T	opt_expand_cb;

    char_u	*def_val[2];	// default values for variable (vi and vim)
#ifdef FEAT_EVAL
    sctx_T	script_ctx;	// script context where the option was last set
# define SCTX_INIT , {0, 0, 0, 1}
#else
# define SCTX_INIT
#endif
};
```
## Q3
修改源码，通过getenv("MSYSTEM") 或 getenv("SHELL")检测来拼接 Unix 风格路径$HOME/.vim
### Answer
## 实现思路

现有代码里已经有一个非常相似的机制可以参考：`set_init_xdg_rtp()`,它在 `UNIX` 平台下,如果检测到用户只有 `$XDG_CONFIG_HOME/vim/vimrc`,就会动态改写 `runtimepath`/`packpath` 的默认值 vim:389-458 。这个函数是在 `set_init_1()` 里,`set_options_default(0)` 把 `p_rtp` 设成宏字符串之后被调用的 vim:678-692 ,说明"运行时覆盖编译期默认值"这条路径在 Vim 里是有先例、可行的。

对于 Windows(`os_dos.h`)平台,`DFLT_RUNTIMEPATH` 硬编码为 `$HOME/vimfiles,...` vim:107-109 ,并通过 `optiondefs.h` 里 `"runtimepath"` 选项表项的 `def_val[VI_DEFAULT]` 赋给 `p_rtp` vim:2246-2250 。

要实现"运行时根据 `MSYSTEM`/`SHELL` 检测,决定用 `~/.vim` 还是 `~/vimfiles`",需要新增一个类似 `set_init_xdg_rtp()` 的函数(例如 `set_init_msys_rtp()`),仅在 `defined(MSWIN)` 下编译,在 `set_init_1()` 中 `set_options_default(0)` 之后调用,通过 `mch_getenv("MSYSTEM")` 或 `mch_getenv("SHELL")` 判断是否处于类 Unix shell 环境,如果是,则用类似 `"~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"` 的字符串覆盖 `options[opt_idx].def_val[VI_DEFAULT]` 和全局变量 `p_rtp`(同时对 `p_pp` 做一样处理),逻辑结构可完全参照 `set_init_xdg_rtp()` 中 `findoption()` + 赋值 `def_val[VI_DEFAULT]` + 赋值全局变量的写法 vim:397-457 。

需要注意几点限制:
- 这只影响 `runtimepath`/`packpath` 的默认值,不会改变 `USR_VIMRC_FILE` 等 vimrc 查找路径的宏(那部分逻辑在别处,如果要一致还需要额外处理 `$MYVIMRC` 探测逻辑,但这部分本身没有像 `DFLT_RUNTIMEPATH` 一样的宏可覆盖点,改动会更复杂)。
- `mch_getenv` 的具体实现和 `set_init_1()`/`common_init_2()` 的调用顺序细节,我从索引中只能确认 `set_init_1(paramp->clean)` 是在 `init_homedir()` 之后于 `common_init_2()` 中被调用 vim:1089-1091 ,但对于 Windows 版本编译宏的具体条件组合(`MSWIN` vs `UNIX` vs `VIMDLL` 等)以及 CI/测试覆盖情况,由于索引大小限制未能完整核对,建议在实际改动前用 Devin 会话直接读取完整的 `option.c`/`os_dos.h` 源码确认。


在仓库 `vim/vim` 中修改 C 源码,让 Windows 版(MSWIN)Vim 在启动时通过环境变量检测当前是否运行在类 Unix shell(如 MSYS2/Git Bash)下,并据此动态选择 `.vim` 风格还是 `vimfiles` 风格的默认 `runtimepath`/`packpath`。

背景:
- `runtimepath`(`p_rtp`)选项的默认值当前来自编译期宏 `DFLT_RUNTIMEPATH`,在 `src/optiondefs.h` 的选项表中被赋给 `def_val[VI_DEFAULT]`(参考 `src/optiondefs.h` 中 `"runtimepath"` 和 `"packpath"` 两个选项定义)。
- Windows 版该宏在 `src/os_dos.h` 中定义为 `"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"`。
- `src/option.c` 中已有一个可参考的先例函数 `set_init_xdg_rtp()`(仅在 `#ifdef UNIX` 编译),它在 `set_init_1()` 里 `set_options_default(0)` 调用之后,通过 `findoption()` 找到 `"runtimepath"`/`"packpath"` 选项在 `options[]` 数组中的索引,重新赋值 `options[opt_idx].def_val[VI_DEFAULT]` 和全局变量 `p_rtp`/`p_pp`,从而在运行时覆盖编译期默认值。这个函数的调用点在 `set_init_1()` 函数体内,`#ifdef UNIX` 块中。

需要实现的改动:
1. 在 `src/option.c` 中新增一个静态函数(例如命名为 `set_init_msys_rtp()`),仅在 `#if defined(MSWIN)` 下编译。该函数逻辑:
   - 用 `mch_getenv("MSYSTEM")` 检测是否存在(MSYS2/Git Bash 环境通常会设置该变量,值如 `MINGW64`/`MSYS` 等);如果不存在,再检查 `mch_getenv("SHELL")` 的值是否包含 `bash`、`zsh`、`sh` 等类 Unix shell 名称字符串作为后备判断。
   - 如果判断为类 Unix 环境,构造一个 Unix 风格的 runtimepath 字符串,如 `"~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"`(可参考 `src/os_unix.h` 中 `DFLT_RUNTIMEPATH` 的 Unix 定义:`"~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"`),并同样构造对应 `packpath` 的值(通常与 runtimepath 一致或用 CLEAN 版本,需要参照 Vim 现有 `packpath` 处理逻辑决定是否加 `after` 部分)。
   - 通过 `findoption((char_u *)"runtimepath")` 找到选项索引,若 >=0,将 `options[opt_idx].def_val[VI_DEFAULT]` 和全局变量 `p_rtp` 都设为新构造的字符串(注意内存管理:字符串需要用 `vim_strsave` 或类似方式分配并在合适时机释放,不能直接赋值字面量指针如果后续代码会尝试 `vim_free` 它;可参照 `set_init_xdg_rtp()` 中 `xdg_rtp` 变量的处理方式,如果是静态/常量字符串则不设置 `P_DEF_ALLOCED` 标志,如果是动态分配则需要设置该标志,具体应参照 `set_init_default_cdpath()` 函数中 `options[opt_idx].flags |= P_DEF_ALLOCED;` 的用法)。
   - 对 `packpath`(`"packpath"` 选项,对应变量 `p_pp`)做同样处理。
2. 在 `src/option.c` 的 `set_init_1()` 函数体中,找到 `set_options_default(0);` 调用之后、`#ifdef UNIX ... set_init_xdg_rtp(); ... #endif` 代码块附近,新增一个 `#if defined(MSWIN)` 块调用新增的 `set_init_msys_rtp()` 函数。确保调用顺序在 `set_options_default(0)` 之后(这样默认值已经被设置一次,再被覆盖),并且在 `#ifdef CLEAN_RUNTIMEPATH ... if (clean_arg) set_init_clean_rtp(); ... #endif` 之前或之后均可,但建议放在其之前,以保证 `--clean` 参数仍然优先生效(即 `--clean` 时不应用 MSYS 检测逻辑,直接使用 `CLEAN_RUNTIMEPATH`)。
3. 检查 `src/os_dos.h` 中是否需要为新逻辑定义额外的宏(例如一个新的 `MSYS_RUNTIMEPATH` 宏,类似 `os_unix.h`/`os_mac.h` 中已有的 `DFLT_RUNTIMEPATH`/`XDG_RUNTIMEPATH` 风格),把 Unix 风格路径字符串定义为宏而不是硬编码在 `option.c` 里,以保持代码风格一致(参考 `src/os_unix.h` 第337-363行 `DFLT_RUNTIMEPATH`/`XDG_RUNTIMEPATH`/`XDG_RUNTIMEPATH_FB`/`CLEAN_RUNTIMEPATH` 几个宏的组织方式)。
4. 为该功能编写/更新测试:在 `src/testdir/` 目录下查找现有的 runtimepath 相关测试(例如涉及 `set_init_xdg_rtp` 或 `--clean` 参数的测试文件),添加新的测试用例,通过设置环境变量 `MSYSTEM` 或 `SHELL` 后启动 vim(在 CI 环境模拟或用 `test_override()`/`getenv()` mock 方式)验证 `&runtimepath` 是否切换为 Unix 风格路径。
5. 更新文档 `runtime/doc/starting.txt` 和/或 `runtime/doc/os_dos.txt`,说明在 MSYS2/Git Bash 环境下 Windows 版 Vim 现在会自动检测并使用 `~/.vim` 风格的 `runtimepath`,并说明检测所依据的环境变量(`MSYSTEM`、`SHELL`)及优先级规则。
6. 确认该改动不会影响 `USR_VIMRC_FILE`/`USR_VIMRC_FILE2` 等 vimrc 查找路径的宏(定义在 `src/os_dos.h` 第16-27行),本任务范围仅限于 `runtimepath`/`packpath` 默认值,不修改 vimrc 文件查找逻辑,除非用户后续要求同步修改。
7. 编译并本地测试该改动在 Windows(MinGW/MSVC)构建下的行为:分别在 cmd.exe(无 `MSYSTEM`/`SHELL`)和 Git Bash/MSYS2 终端(有 `MSYSTEM`)下启动 vim,执行 `:echo &runtimepath` 验证默认值是否按预期切换。
### Citations
**File:** src/option.c (L389-458)
```c
#ifdef UNIX
/*
 * Change 'runtimepath' and 'packdir' to '$XDG_CONFIG_HOME/vim' if the only
 * vimrc found is located in '$XDG_CONFIG_HOME/vim/vimrc'.
 * In case the '$XDG_CONFIG_HOME' variable is not set, '$HOME/.config' is used
 * as a fallback as is defined in the XDG base dir specification:
 * <https://specifications.freedesktop.org/basedir/latest/>
 */
    static void
set_init_xdg_rtp(void)
{
    int		opt_idx;
    int		has_xdg_env = TRUE;
    int		should_free_xdg_dir = FALSE;
    char_u	*vimrc1 = NULL;
    char_u	*vimrc2 = NULL;
    char_u	*xdg_dir = NULL;
    char_u	*xdg_rtp = NULL;
    string_T	vimrc_xdg = {NULL, 0};

    // initialize chartab, so we can expand $HOME
    (void)init_chartab();
    vimrc1 = expand_env_save((char_u *)USR_VIMRC_FILE);
    vimrc2 = expand_env_save((char_u *)USR_VIMRC_FILE2);

    xdg_dir = mch_getenv("XDG_CONFIG_HOME");
    if (!xdg_dir)
    {
	xdg_dir = expand_env_save((char_u *)"~/.config");
	should_free_xdg_dir = TRUE;
	has_xdg_env = FALSE;
    }
    concat_fnames(xdg_dir, STRLEN(xdg_dir),
	(char_u *)"vim/vimrc", STRLEN_LITERAL("vim/vimrc"), TRUE, &vimrc_xdg);

    if (file_is_readable(vimrc1) || file_is_readable(vimrc2) ||
	    !file_is_readable(vimrc_xdg.string))
	goto theend;

    xdg_rtp = has_xdg_env ? (char_u *)XDG_RUNTIMEPATH
	: (char_u *)XDG_RUNTIMEPATH_FB;

    if ((opt_idx = findoption((char_u *)"runtimepath")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = xdg_rtp;
    p_rtp = xdg_rtp;

    if ((opt_idx = findoption((char_u *)"packpath")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = xdg_rtp;
    p_pp = xdg_rtp;

# if defined(XDG_VDIR) && defined(FEAT_SESSION)
    if ((opt_idx = findoption((char_u *)"viewdir")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = (char_u *)XDG_VDIR;
    p_vdir = (char_u *)XDG_VDIR;
# endif

theend:
    vim_free(vimrc1);
    vim_free(vimrc2);
    vim_free(vimrc_xdg.string);
    if (should_free_xdg_dir)
	vim_free(xdg_dir);
}
#endif
```
**File:** src/option.c (L678-692)
```c
    /*
     * Set all the options (except the terminal options) to their default
     * value.  Also set the global value for local options.
     */
    set_options_default(0);

#ifdef UNIX
    set_init_xdg_rtp();
    set_init_restricted_mode();
#endif

#ifdef CLEAN_RUNTIMEPATH
    if (clean_arg)
	set_init_clean_rtp();
#endif
```
**File:** src/os_dos.h (L107-109)
```text
#define DFLT_ERRORFILE		"errors.err"
#define DFLT_RUNTIMEPATH	"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
#define CLEAN_RUNTIMEPATH	"$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
```
**File:** src/optiondefs.h (L2246-2250)
```text
    {"runtimepath", "rtp",  P_STRING|P_VI_DEF|P_EXPAND|P_ONECOMMA|P_NODUP
								    |P_SECURE,
			    (char_u *)&p_rtp, PV_NONE, NULL, NULL,
			    {(char_u *)DFLT_RUNTIMEPATH, (char_u *)0L}
			    SCTX_INIT},
```
**File:** src/main.c (L1089-1091)
```c
    init_homedir();		// find real value of $HOME
    set_init_1(paramp->clean);
    TIME_MSG("inits 1");
```
## Q4
请给出具体代码实现，测试代码，更新文档，和本地测试方法
### Answer
需要在ask-only模式下回答：不能输出<plan>，但用户要求具体代码实现。应该给出概念性的示例代码（作为说明，不是正式提交的补丁），并明确指出这超出了纯问答范围，本质仍是源码修改建议。
提醒一下：这类"写具体实现代码+测试代码"的请求本质上是要我产出可提交的源码补丁，这超出了当前问答模式的范围——我只能基于已检索到的代码给出概念性/示意性的实现思路和示例片段，不能保证下面的代码可以直接编译通过或已经在真实仓库里验证过。如果需要真正落地、编译、跑测试，需要在实际开发环境（或 Devin session）里完成。

## 参考实现思路（示意代码，非最终补丁）

### 1. 宏定义 `src/os_dos.h`

Unix 侧的 `os_unix.h` 已经用宏组织好了 `DFLT_RUNTIMEPATH` / `XDG_RUNTIMEPATH` / `XDG_RUNTIMEPATH_FB` / `CLEAN_RUNTIMEPATH` 四个变体：
```c
#  define DFLT_RUNTIMEPATH  "~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"
#  define XDG_RUNTIMEPATH   "$XDG_CONFIG_HOME/vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$XDG_CONFIG_HOME/vim/after"
#  define XDG_RUNTIMEPATH_FB "~/.config/vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.config/vim/after"
#  define CLEAN_RUNTIMEPATH "$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
``` vim:356-359 

在 `src/os_dos.h` 里加一个新宏 `MSYS_RUNTIMEPATH`，风格参照原有 `DFLT_RUNTIMEPATH`：
```c
#ifndef MSYS_RUNTIMEPATH
# define MSYS_RUNTIMEPATH \
    "~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"
#endif
```
`DFLT_RUNTIMEPATH` 本身保持不变 vim:107-109 ——这是关键点：默认值仍是 Windows 风格，新增逻辑只在运行时“覆盖”它，跟 `XDG_RUNTIMEPATH` 的处理方式完全一致。

### 2. `src/option.c` 新函数（仿照 `set_init_xdg_rtp`）

```c
#if defined(MSWIN)
/*
 * If running inside an MSYS2 / Git-Bash / Cygwin-like shell (detected via
 * $MSYSTEM or a POSIX-style $SHELL), switch 'runtimepath' and 'packpath'
 * to the Unix-style "~/.vim" layout instead of "~/vimfiles".
 */
    static void
set_init_msys_rtp(void)
{
    int		opt_idx;
    char_u	*msystem = mch_getenv("MSYSTEM");
    char_u	*shell = mch_getenv("SHELL");
    int		is_unix_shell = FALSE;

    if (msystem != NULL && *msystem != NUL)
	is_unix_shell = TRUE;
    else if (shell != NULL &&
	    (vim_strchr(shell, '/') != NULL ||
	     strstr((char *)shell, "bash") != NULL ||
	     strstr((char *)shell, "zsh")  != NULL))
	is_unix_shell = TRUE;

    if (!is_unix_shell)
	return;

    if ((opt_idx = findoption((char_u *)"runtimepath")) < 0)
	return;
    options[opt_idx].def_val[VI_DEFAULT] = (char_u *)MSYS_RUNTIMEPATH;
    p_rtp = (char_u *)MSYS_RUNTIMEPATH;

    if ((opt_idx = findoption((char_u *)"packpath")) < 0)
	return;
    options[opt_idx].def_val[VI_DEFAULT] = (char_u *)MSYS_RUNTIMEPATH;
    p_pp = (char_u *)MSYS_RUNTIMEPATH;
}
#endif
```

要点说明（结合已有代码的约束）：
- `set_init_xdg_rtp()` 在赋值前先用 `expand_env_save()` 展开过 `~`/`$HOME` 再判断文件是否存在 vim:397-415 ；但它最终赋给 `p_rtp`/`def_val[VI_DEFAULT]` 的字符串本身（`xdg_rtp`）**没有展开**，仍是带 `$XDG_CONFIG_HOME` 的原始字符串——因为 `'runtimepath'` 选项有 `P_EXPAND` 标志，会在使用时自动展开环境变量。这里 `MSYS_RUNTIMEPATH` 同理不需要预先展开，可以直接赋值字面量。
- 因为 `MSYS_RUNTIMEPATH` 是编译期字面量（不是 `vim_strsave` 动态分配的），**不要**给 `options[opt_idx].flags` 加 `P_DEF_ALLOCED`，否则后续 Vim 试图 `vim_free()` 一个字符串常量会导致崩溃——这一点在 `set_init_xdg_rtp()` 里同样是隐含处理的（它对 `xdg_rtp` 也不设 `P_DEF_ALLOCED`，因为 `XDG_RUNTIMEPATH`/`XDG_RUNTIMEPATH_FB` 都是宏字符串常量或静态分配后从不释放）。

### 3. 调用点 `set_init_1()`

```c
#ifdef UNIX
    set_init_xdg_rtp();
    set_init_restricted_mode();
#endif
#if defined(MSWIN)
    set_init_msys_rtp();
#endif

#ifdef CLEAN_RUNTIMEPATH
    if (clean_arg)
	set_init_clean_rtp();
#endif
```
放在 `set_options_default(0)` 之后、`clean_arg` 分支之前，与现有 `set_init_xdg_rtp()` 的调用顺序保持一致 vim:678-692 ，这样 `--clean` 仍然优先生效并完全跳过检测逻辑。

## 测试代码（示意）

Vim 的 `src/testdir/test_startup.vim` 里已经有针对 `XDG_CONFIG_HOME`/runtimepath 的测试用例作为参照模式（通过 `writefile()` 造一个假的 `HOME`，设置对应环境变量，`RunVim()`/`exec_system()` 启动子进程后检查 `&runtimepath`的输出）。仿照这个模式，新增测试大致形态：

```vim
func Test_start_with_msystem_env()
  CheckMSWindows
  " 构造一个假的 $HOME，不放任何 vimrc
  let fake_home = 'Xhome'
  call mkdir(fake_home, 'p')
  let env_save = $HOME
  let $HOME = fake_home

  let env_msystem_save = $MSYSTEM
  let $MSYSTEM = 'MINGW64'

  let after = ['call writefile([&runtimepath], "Xrtp_result")']
  call writefile(after, 'Xafter.vim')
  call system($'{GetVimCommand()} -es -u NONE -S Xafter.vim -c cquit')

  let result = readfile('Xrtp_result')[0]
  call assert_match('[\\/]\.vim', result)
  call assert_notmatch('vimfiles', result)

  call delete('Xafter.vim')
  call delete('Xrtp_result')
  call delete(fake_home, 'rf')
  let $HOME = env_save
  let $MSYSTEM = env_msystem_save
endfunc
```

这只是示意骨架，具体断言方式、`CheckMSWindows` guard、`GetVimCommand()` 辅助函数名是否存在，需要对照 `test_startup.vim` 中已有的 `Test_*rtp*`/`Test_*xdg*` 相关测试用例的实际写法调整（我未能取得该文件里 XDG 相关测试的完整代码，只确认了它存在两处 `XDG_CONFIG_HOME` 引用 vim:1-1 ，具体行号和写法建议在实际开发时打开文件核对）。

## 文档更新（示意）

在 `runtime/doc/os_dos.txt` 的 *dos-locations* 一节里补充说明，紧跟现有关于 `_vimrc`/`vimfiles` 位置的段落 vim:23-54 ：

```
If Vim detects it is running inside an MSYS2 or Git-Bash-like shell
(the $MSYSTEM environment variable is set, or $SHELL looks like a Unix
shell), it will use "~/.vim" instead of "~/vimfiles" as the default
'runtimepath' entry, matching Unix conventions.
```

在 `runtime/doc/starting.txt` 中 *initialization* 一节的 MS-Windows 段落后加一条 Note，说明检测逻辑及优先级（`--clean` 完全跳过该检测）。

## 本地测试方法

1. **编译**：在 Windows 下用 MinGW（MSYS2 环境）或 MSVC 按现有 `src/INSTALLpc.txt`/`Makefile` 说明编译，确保 `src/option.c`、`src/os_dos.h` 的改动被纳入编译单元。
2. **不带 MSYSTEM 的场景**（普通 `cmd.exe`）：
   ```
   set MSYSTEM=
   vim -u NONE -c "echo &runtimepath" -c "qa!"
   ```
   预期结果仍含 `vimfiles`。
3. **带 MSYSTEM 的场景**（MSYS2/Git Bash 终端里）：
   ```
   echo $MSYSTEM        # 确认非空，如 MINGW64
   vim -u NONE -c "echo &runtimepath" -c "qa!"
   ```
   预期结果变为含 `.vim` 而不含 `vimfiles`。
4. **`--clean` 场景**：
   ```
   vim --clean -c "echo &runtimepath" -c "qa!"
   ```
   预期结果应为 `CLEAN_RUNTIMEPATH`（`$VIM/vimfiles,...`），不受 MSYSTEM 检测影响，验证优先级顺序正确。
5. **回归测试**：运行 `make -C src/testdir test_startup` 或对应的 `.bat` 测试脚本，确认新增测试通过且现有 `Test_*rtp*` 测试未被破坏。

以上代码和测试均为基于已检索到的 `set_init_xdg_rtp()` 等既有实现模式推导出的示意实现，并未经过实际编译/运行验证，落地前需要在真实源码环境中核对函数签名、头文件包含（如 `mch_getenv`、`vim_strchr` 的声明位置）、以及 `test_startup.vim` 中现有测试的确切写法。 vim:389-458 vim:678-692 vim:337-363 vim:107-109 vim:2246-2250
### Citations
**File:** src/os_unix.h (L337-363)
```text
#ifndef DFLT_RUNTIMEPATH

# ifdef VMS
#  define DFLT_RUNTIMEPATH      "sys$login:vimfiles,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,sys$login:vimfiles/after"
#  define CLEAN_RUNTIMEPATH      "$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
# else
#  ifdef RUNTIME_GLOBAL
#   ifdef RUNTIME_GLOBAL_AFTER
#    define DFLT_RUNTIMEPATH	"~/.vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL_AFTER ",~/.vim/after"
#    define XDG_RUNTIMEPATH	"$XDG_CONFIG_HOME/vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL_AFTER ",$XDG_CONFIG_HOME/vim/after"
#    define XDG_RUNTIMEPATH_FB	"~/.config/vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL_AFTER ",~/.config/vim/after"
#    define CLEAN_RUNTIMEPATH	RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL_AFTER
#   else
#    define DFLT_RUNTIMEPATH	"~/.vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL "/after,~/.vim/after"
#    define XDG_RUNTIMEPATH	"$XDG_CONFIG_HOME/vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL "/after,$XDG_CONFIG_HOME/vim/after"
#    define XDG_RUNTIMEPATH_FB	"~/.config/vim," RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL "/after,~/.config/vim/after"
#    define CLEAN_RUNTIMEPATH	RUNTIME_GLOBAL ",$VIMRUNTIME," RUNTIME_GLOBAL "/after"
#   endif
#  else
#   define DFLT_RUNTIMEPATH	"~/.vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.vim/after"
#   define XDG_RUNTIMEPATH	"$XDG_CONFIG_HOME/vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,$XDG_CONFIG_HOME/vim/after"
#   define XDG_RUNTIMEPATH_FB	"~/.config/vim,$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after,~/.config/vim/after"
#   define CLEAN_RUNTIMEPATH	"$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
#  endif
# endif

#endif
```
**File:** src/os_dos.h (L107-109)
```text
#define DFLT_ERRORFILE		"errors.err"
#define DFLT_RUNTIMEPATH	"$HOME/vimfiles,$VIM/vimfiles,$VIMRUNTIME,$HOME/vimfiles/after,$VIM/vimfiles/after"
#define CLEAN_RUNTIMEPATH	"$VIM/vimfiles,$VIMRUNTIME,$VIM/vimfiles/after"
```
**File:** src/option.c (L389-458)
```c
#ifdef UNIX
/*
 * Change 'runtimepath' and 'packdir' to '$XDG_CONFIG_HOME/vim' if the only
 * vimrc found is located in '$XDG_CONFIG_HOME/vim/vimrc'.
 * In case the '$XDG_CONFIG_HOME' variable is not set, '$HOME/.config' is used
 * as a fallback as is defined in the XDG base dir specification:
 * <https://specifications.freedesktop.org/basedir/latest/>
 */
    static void
set_init_xdg_rtp(void)
{
    int		opt_idx;
    int		has_xdg_env = TRUE;
    int		should_free_xdg_dir = FALSE;
    char_u	*vimrc1 = NULL;
    char_u	*vimrc2 = NULL;
    char_u	*xdg_dir = NULL;
    char_u	*xdg_rtp = NULL;
    string_T	vimrc_xdg = {NULL, 0};

    // initialize chartab, so we can expand $HOME
    (void)init_chartab();
    vimrc1 = expand_env_save((char_u *)USR_VIMRC_FILE);
    vimrc2 = expand_env_save((char_u *)USR_VIMRC_FILE2);

    xdg_dir = mch_getenv("XDG_CONFIG_HOME");
    if (!xdg_dir)
    {
	xdg_dir = expand_env_save((char_u *)"~/.config");
	should_free_xdg_dir = TRUE;
	has_xdg_env = FALSE;
    }
    concat_fnames(xdg_dir, STRLEN(xdg_dir),
	(char_u *)"vim/vimrc", STRLEN_LITERAL("vim/vimrc"), TRUE, &vimrc_xdg);

    if (file_is_readable(vimrc1) || file_is_readable(vimrc2) ||
	    !file_is_readable(vimrc_xdg.string))
	goto theend;

    xdg_rtp = has_xdg_env ? (char_u *)XDG_RUNTIMEPATH
	: (char_u *)XDG_RUNTIMEPATH_FB;

    if ((opt_idx = findoption((char_u *)"runtimepath")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = xdg_rtp;
    p_rtp = xdg_rtp;

    if ((opt_idx = findoption((char_u *)"packpath")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = xdg_rtp;
    p_pp = xdg_rtp;

# if defined(XDG_VDIR) && defined(FEAT_SESSION)
    if ((opt_idx = findoption((char_u *)"viewdir")) < 0)
	goto theend;

    options[opt_idx].def_val[VI_DEFAULT] = (char_u *)XDG_VDIR;
    p_vdir = (char_u *)XDG_VDIR;
# endif

theend:
    vim_free(vimrc1);
    vim_free(vimrc2);
    vim_free(vimrc_xdg.string);
    if (should_free_xdg_dir)
	vim_free(xdg_dir);
}
#endif
```
**File:** src/option.c (L678-692)
```c
    /*
     * Set all the options (except the terminal options) to their default
     * value.  Also set the global value for local options.
     */
    set_options_default(0);

#ifdef UNIX
    set_init_xdg_rtp();
    set_init_restricted_mode();
#endif

#ifdef CLEAN_RUNTIMEPATH
    if (clean_arg)
	set_init_clean_rtp();
#endif
```
**File:** src/testdir/test_startup.vim (L1-1)
```text
" Tests for startup.
```
**File:** runtime/doc/os_dos.txt (L23-54)
```text
1. File locations					*dos-locations*

If you keep the Vim executable in the directory that contains the help and
syntax subdirectories, there is no need to do anything special for Vim to
work.  No registry entries or environment variables need to be set.  Just make
sure that the directory is in your search path, or use a shortcut on the
desktop.

Your vimrc files ("_vimrc" and "_gvimrc") are normally located one directory
up from the runtime files.  If you want to put them somewhere else, set the
environment variable $VIM to the directory where you keep them.  Example: >
	set VIM=C:\user\piet
Will find "c:\user\piet\_vimrc".
Note: This would only be needed when the computer is used by several people.
Otherwise it's simpler to keep your _vimrc file in the default place.

If you move the executable to another location, you also need to set the $VIM
environment variable.  The runtime files will be found in "$VIM/vim{version}".
Example: >
	set VIM=E:\vim
Will find the version 8.2 runtime files in "e:\vim\vim82".
Note: This is _not_ recommended.  The preferred way is to keep the executable
in the runtime directory.

If you move your executable AND want to put your "_vimrc" and "_gvimrc" files
somewhere else, you must set $VIM to where you vimrc files are, and set
$VIMRUNTIME to the runtime files.  Example: >
	set VIM=C:\usr\piet
	set VIMRUNTIME=E:\vim\vim82
Will find "c:\user\piet\_vimrc" and the runtime files in "e:\vim\vim82".

See |$VIM| and |$VIMRUNTIME| for more information.
```
**File:** src/optiondefs.h (L2246-2250)
```text
    {"runtimepath", "rtp",  P_STRING|P_VI_DEF|P_EXPAND|P_ONECOMMA|P_NODUP
								    |P_SECURE,
			    (char_u *)&p_rtp, PV_NONE, NULL, NULL,
			    {(char_u *)DFLT_RUNTIMEPATH, (char_u *)0L}
			    SCTX_INIT},
```
