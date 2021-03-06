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
<prefix> - c     # new windows
<prefix> - ,     # rename windows
<prefix> - [ / ] # pre or next window
<prefix> - w     # change windows
<prefix> - s     # change sessions

# panel
<prefix> - = / - # split or vertical split panel
<prefix> - <c-h> # hjkl resize panel

# config or plugin
<prefix> - r     # reload tmux.conf
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
