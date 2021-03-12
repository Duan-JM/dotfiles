Vim Configuration
=================
This is my vim configuration and always update to my latest used.

### Plugins
Plugins can be seen in file `./autoload/plugin_configs.vim`.

### Installation
```
bash ./install.sh
```

### Most used Command

```bash
:Gdiffsplit # vim-fugitive
:gv         # gv see commits
:Vista      # 打开查看当前文件内的函数与变量
:g<         # 可以用来你不小心跳转了，或者执行了什么指令，再回来 
# The g< command can be used to see the last page of previous command output.
:w !sudo tee % # 当你用普通用户没有写权限时很好用。
```

### Command Shortcuts

```bash
# 自定义快捷键
<space>       # leader
<leader> r    # run current script below

<leader> p    # leaderF 当前目录内搜索文件，
              # <c-n> 或 <c-p> 选中要的文件后，<c-]> 或 <c-x> 新窗口打开

<leader> nt   # 左侧打开文件目录
<leader> jd   # 函数跳转，一般用 <c-o> 返回
]<space>      # 下面加一行空行，同理 [<space>

# 常用默认快捷键
<c-\><c-n>    # Termianl 返回 Noraml model
<c-w> h       # 切换窗口，同理 hjkl 为方向键
<c-w> =       # 调整窗口大小，同理还有 _ | < > + -
fFtT <char>   # 行内跳转，使用 QuickScope 进行辅助高亮
])            # 跳到下一个)，同理[(
]m / ]M       # 跳到函数方法的末尾      

# 插入模式下的删除
<c-u> # 向前删除一行
<c-h> # 前删除一个字母
<c-w> # 向前删除一个单词

# 插件
<leader> y # 看黏贴的记录
<leader> ` # 呼叫 Floaterm 终端

<leader>fb # buffer list
<leader>ft # buftags
<leader>fl # search line
<c-b>      # search in current buffer
<c-f>      # search the content in the current dir
go         # recall rg operations
<leader> <c-f> <search-parttern> # search target pattern current files 

<c-y>     # confirm snippet from tabnine
```

### Unfrequency Command Shortcuts

1. AutoComplute

    ```bash
    <c-x><c-l> # 整行补全, 在 complet 选项定义范围内查找
    <c-x><c-n> # 当前文本的关键词补全，关键词根据 iskeyword 定义
    <c-x><c-k> # 从 dictionary 里面查找单词进行补全
    <c-x><c-f> # 文件名补全
    ```

2. Value Calculator

    在 `insert` 模式下输入 `ctrl+=` 。

### Vim Performance Debug

1. Init Debug log

    ```bash
    vim --startuptime <file> open_file
    # :help startup-options to see how to defin startup operations
    ```

2. Run debug

    ```bash
    # 目的是 debug 一些日常卡顿的现象，个人有时候会运行时 vim 卡死，这时候就需要 debug 了
    vim -V13<your/log/file/path> open_file

    # :h 'verbose' 去看输出日志的等级

    :message # 看最近的执行的指令，还有报错的内容
    :echo errmsg # 查看最近错信息
    :h errors # 查看各种报错代码的意思

    # 也可以做成 function
    function! ToggleVerbose()
        if !&verbose
            set verbosefile=~/.log/vim/verbose.log
            set verbose=15
        else
            set verbose=0
            set verbosefile=
        endif
    endfunction
    ```

### Reference
- [Is there a "vim runtime log"?](https://stackoverflow.com/questions/3025615/is-there-a-vim-runtime-log)
- [如何调试 Vim 脚本 | Harttle Land](https://harttle.land/2018/12/05/vim-debug.html)
