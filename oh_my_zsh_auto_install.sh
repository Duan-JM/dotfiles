# os check
if [ "$(uname)"=="Darwin" ]; then
  echo "Dectect MacOS"

  if command -v brew >/dev/null 2>&1; then 
    echo 'brew detected, skip install brew' 
  else 
    echo 'no exists brew, installing' 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    brew install git
  fi

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    brew install zsh
    chsh -s /bin/zsh
  fi

  if [ ! -d "~/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  else
    echo 'oh my zsh detected, skip installing'
  fi

elif [ "$(uname)"=="Linux" ]; then

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    sudo apt install git
  fi

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    sudo apt install zsh
    chsh -s /bin/zsh
  fi

  if [ ! -d "~/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
  else
    echo 'oh my zsh detected, skip installing'
  fi

else
  echo "Scripts do not support $(uname)"
fi

echo "Copy the Configure Files"

cp ./zsh/zshrc ~/.zshrc
cp -rf ./zsh/zsh-config ~/.zsh-config
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

