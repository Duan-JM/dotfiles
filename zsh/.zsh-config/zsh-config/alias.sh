# Temporary Settings
alias github='cd ~/Documents/Github'
alias zshrc='vim ~/.zshrc'
alias vimrc='vim ~/.vimrc'
alias vi='nvim'
alias vim='nvim'
alias wk='/Users/duan-jm/Documents/Records/工作'
alias pg='cd ~/Documents/CodeTest'
alias cpv='rsync -ah --info=progress2'
alias task='asynctask -f'
alias gch='git branch -a | fzf| tr -d "[:space:]"'
# alias python3='/opt/homebrew/opt/python@3.9/Frameworks/Python.framework/Versions/3.9/bin/python3.9'

# Most often
alias proxy='export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890'
alias unproxy='unset all_proxy https_proxy http_proxy'
alias ggrep='git grep --break --heading -n'
alias mnt='mount | grep -E ^/dev | column -t'
alias count='find . -type f | wc -l'


# other's configure
# Advanced Aliases.

# ls, the common ones I use a lot shortened for rapid fire usage
alias grep='grep --color'
alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '
alias t='tail -f'

# Command line head / tail shortcuts
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g M="| most"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g P="2>&1| pygmentize -l pytb"

alias h='history'
alias hgrep="fc -El 0 | grep"
alias help='man'
alias p='ps -f'
alias sortnr='sort -n -r'
alias unexport='unset'

alias rmi='rm -i'
alias cpi='cp -i'
alias mvi='mv -i'

#Git self configure

#change gd(git diff) need to manually change in the zsh git plugin
function gdd() {
	params="$@"
  params=`scmpuff expand "$@" 2>/dev/null`

  if [ $# -eq 0 ]; then
    git difftool --no-prompt --extcmd "icdiff --line-numbers --no-bold" | less
  elif [ ${#params} -eq 0 ]; then
    git difftool --no-prompt --extcmd "icdiff --line-numbers --no-bold" "$@" | less
  else
    git difftool --no-prompt --extcmd "icdiff --line-numbers --no-bold" "$params" | less
  fi
}


# change github source to boost up download speed
function gcn() {
  git_url=${1}
  remain_str=${git_url##*https://github.com/}
  head_str="https://github.com.cnpmjs.org/"
  `git clone ${head_str}${remain_str}`
}
