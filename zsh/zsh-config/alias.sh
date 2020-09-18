# Temporary Settings
alias blog='cd ~/Documents/Github/VDeamoV.github.io'
alias github='cd ~/Documents/Github'
alias zshrc='vim ~/.zshrc'
alias vimrc='vim ~/.vimrc'
alias vi='nvim'
alias vim='nvim'
alias pg='cd ~/Documents/Coding/Test'
alias cpv='rsync -ah --info=progress2'
alias task='asynctask -f'

# Most often
alias proxy='export all_proxy=socks5://127.0.0.1:7890'
alias unproxy='unset all_proxy'
alias sublime='open -a Sublime\ Text'
alias vscode='open -a Visual\ Studio\ Code'
alias xc='open -a "Xcode"'
alias ggrep='git grep --break --heading -n'
alias mnt='mount | grep -E ^/dev | column -t'
alias count='find . -type f | wc -l'


# other's configure
# Advanced Aliases.

# ls, the common ones I use a lot shortened for rapid fire usage
alias l='ls -lFh'     #size,show type,human readable
alias la='ls -lAFh'   #long list,show almost all,show type,human readable
alias lr='ls -tRFh'   #sorted by date,recursive,show type,human readable
alias lt='ls -ltFh'   #long list,sorted by date,show type,human readable
alias ll='ls -l'      #long list
alias ldot='ls -ld .*'
alias lS='ls -1FSsh'
alias lart='ls -1Fcart'
alias lrt='ls -1Fcrt'
alias lt='du -sh * | sort -h'


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

alias dud='du -d 1 -h'
alias duf='du -sh *'
alias fd='find . -type d -name'
alias ff='find . -type f -name'

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
function gd() {
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

