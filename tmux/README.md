Tmux Configuration
==================
### Installation
```
bash ./install.sh
```

### Common Command / Shortcuts

```python
# basic
tmux a -t <session-name> # reattach
tmux kill-server # kill server
tmux new -s <session-name>

# windows / session
<prefix> - n     # new windows
<prefix> - [ / ] # pre or next window
<prefix> - w     # change windows
<prefix> - s     # change sessions

# panel
<prefix> - = / - # split or vertical split panel
<prefix> - <c-h> # hjkl resize panel
<prefix> - h/j/k/l # move between panes

# config or plugin
<prefix> - r     # reload tmux.conf
<prefix> - R     # reload tmux.conf and refresh client
<prefix> - I     # install plugin with tpm
<prefix> - U     # update plugin
<prefix> - <c-s> # save layout
<prefix> - <c-r> # reload layout

# different mode
<prefix> - v   # copy mode
# press space to start copy then enter to end
# use <prefix> - p to paste
<prefix> -b    # sync mode
```
