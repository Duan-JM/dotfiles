for gem_bin in "$HOME"/.gem/ruby/*/bin(N) /opt/homebrew/lib/ruby/gems/*/bin(N) /usr/local/lib/ruby/gems/*/bin(N); do
  [[ -d "$gem_bin" ]] && path=("$gem_bin" $path)
done

typeset -U path
